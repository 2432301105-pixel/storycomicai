"""Export job lifecycle and artifact generation."""

from __future__ import annotations

import io
import logging
import uuid
import zipfile
from datetime import UTC, datetime, timedelta
from pathlib import Path

import jwt
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from api.app.core.config import settings
from api.app.db.session import SessionLocal
from api.app.models.export_job import ExportJob, ExportPreset, ExportStatus, ExportType
from api.app.models.project import Project
from api.app.models.user import User
from api.app.schemas.export import ExportCreateData, ExportCreateRequest, ExportStatusData
from api.app.services.comic_package_service import ComicPackageService
from api.app.services.exceptions import DomainError
from api.app.services.project_service import ProjectService

logger = logging.getLogger(__name__)


class ExportService:
    """Creates export jobs and serves artifact download URLs."""

    def __init__(self) -> None:
        self.project_service = ProjectService()
        self.comic_package_service = ComicPackageService()

    def create_export(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: ExportCreateRequest,
    ) -> ExportCreateData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        if not project.is_unlocked:
            raise DomainError(
                code="PAYWALL_REQUIRED",
                message="Unlock full story to export this comic.",
                status_code=403,
            )

        job = ExportJob(
            project_id=project.id,
            export_type=payload.type,
            preset=payload.preset,
            include_cover=payload.include_cover,
            status=ExportStatus.QUEUED,
            progress_pct=0,
            retryable=True,
        )
        db.add(job)
        db.commit()
        db.refresh(job)

        if settings.job_queue_mode == "inline":
            self.run_export_job(job_id=job.id)
            db.refresh(job)
        else:
            self._enqueue_export(job_id=job.id, project_id=project.id)

        return ExportCreateData(
            jobId=job.id,
            projectId=project.id,
            type=job.export_type,
            status=job.status,
        )

    def get_export_status(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
        base_url: str,
    ) -> ExportStatusData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        job = self._get_export_job_or_404(db=db, project_id=project.id, job_id=job_id)
        artifact_url = None
        if job.status == ExportStatus.SUCCEEDED and job.artifact_path:
            artifact_url = self._build_download_url(
                base_url=base_url.rstrip("/"),
                project_id=project.id,
                job_id=job.id,
            )

        return ExportStatusData(
            jobId=job.id,
            projectId=project.id,
            type=job.export_type,
            status=job.status,
            progressPct=job.progress_pct,
            artifactUrl=artifact_url,
            errorCode=job.error_code,
            errorMessage=job.error_message,
            retryable=job.retryable,
        )

    def download_artifact(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
        token: str,
    ) -> FileResponse:
        self._validate_download_token(token=token, project_id=project_id, job_id=job_id)
        job = self._get_export_job_or_404(db=db, project_id=project_id, job_id=job_id)
        if job.status != ExportStatus.SUCCEEDED or not job.artifact_path:
            raise DomainError(
                code="EXPORT_NOT_READY",
                message="Export artifact is not ready.",
                status_code=409,
            )

        artifact_path = Path(job.artifact_path)
        if not artifact_path.exists():
            raise DomainError(
                code="INVALID_ARTIFACT",
                message="Export artifact is no longer available.",
                status_code=410,
            )

        return FileResponse(
            artifact_path,
            media_type=self._artifact_media_type(job.export_type),
            filename=job.artifact_filename or artifact_path.name,
        )

    def run_export_job(self, *, job_id: uuid.UUID) -> None:
        db = SessionLocal()
        job: ExportJob | None = None
        try:
            job = db.get(ExportJob, job_id)
            if job is None:
                raise DomainError(
                    code="EXPORT_JOB_NOT_FOUND",
                    message="Export job not found.",
                    status_code=404,
                )

            project = db.get(Project, job.project_id)
            if project is None:
                raise DomainError(
                    code="PROJECT_NOT_FOUND",
                    message="Project not found for export job.",
                    status_code=404,
                )

            job.status = ExportStatus.RUNNING
            job.progress_pct = 20
            job.error_code = None
            job.error_message = None
            db.add(job)
            db.commit()

            artifact_bytes, filename = self._build_artifact(project=project, job=job)
            artifact_path = self._write_artifact(job_id=job.id, filename=filename, payload=artifact_bytes)

            job.status = ExportStatus.SUCCEEDED
            job.progress_pct = 100
            job.artifact_path = str(artifact_path)
            job.artifact_filename = filename
            job.retryable = False
            db.add(job)
            db.commit()
        except DomainError:
            raise
        except Exception as exc:
            logger.exception("Export job failed", extra={"job_id": str(job_id)})
            if job is not None:
                db.rollback()
                job.status = ExportStatus.FAILED
                job.progress_pct = 100
                job.error_code = "EXPORT_FAILED"
                job.error_message = str(exc)
                job.retryable = True
                db.add(job)
                db.commit()
            raise DomainError(
                code="EXPORT_FAILED",
                message="Failed to generate export artifact.",
                status_code=503,
            ) from exc
        finally:
            db.close()

    def _enqueue_export(self, *, job_id: uuid.UUID, project_id: uuid.UUID) -> None:
        try:
            from celery import Celery

            client = Celery(
                "storycomicai_api_exports",
                broker=settings.celery_broker_url,
                backend=settings.celery_result_backend,
            )
            client.send_task(
                name="workers.export.generate",
                kwargs={"job_id": str(job_id), "project_id": str(project_id)},
                task_id=str(job_id),
                queue="exports",
            )
        except Exception as exc:
            logger.exception("Failed to enqueue export job", extra={"job_id": str(job_id)})
            raise DomainError(
                code="QUEUE_ENQUEUE_FAILED",
                message="Failed to enqueue export job.",
                status_code=503,
            ) from exc

    @staticmethod
    def _get_export_job_or_404(*, db: Session, project_id: uuid.UUID, job_id: uuid.UUID) -> ExportJob:
        job = db.scalar(
            select(ExportJob).where(ExportJob.id == job_id, ExportJob.project_id == project_id)
        )
        if job is None:
            raise DomainError(
                code="EXPORT_JOB_NOT_FOUND",
                message="Export job not found.",
                status_code=404,
            )
        return job

    def _build_artifact(self, *, project: Project, job: ExportJob) -> tuple[bytes, str]:
        title_slug = self._project_title_slug(project.title)
        if job.export_type == ExportType.PDF:
            filename = f"{title_slug}-storycomicai.pdf"
            return self._build_pdf(project=project), filename
        filename = f"{title_slug}-storycomicai-images.zip"
        return self._build_image_bundle(project=project, include_cover=job.include_cover), filename

    def _build_pdf(self, *, project: Project) -> bytes:
        lines = [
            project.title,
            "",
            f"Style: {project.style.replace('_', ' ').title()}",
            f"Pages: {self.comic_package_service.page_count(project)}",
            "",
            "StoryComicAI export preview",
        ]
        content_stream = self._pdf_text_stream(lines)
        return self._minimal_pdf(content_stream)

    def _build_image_bundle(self, *, project: Project, include_cover: bool) -> bytes:
        buffer = io.BytesIO()
        page_count = self.comic_package_service.page_count(project)
        with zipfile.ZipFile(buffer, mode="w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(
                "manifest.txt",
                "\n".join(
                    [
                        f"title={project.title}",
                        f"style={project.style}",
                        f"pages={page_count}",
                        f"include_cover={str(include_cover).lower()}",
                    ]
                ),
            )
            if include_cover:
                archive.writestr("cover.svg", self._svg_markup(title=project.title, subtitle="Cover"))
            for page_number in range(1, page_count + 1):
                archive.writestr(
                    f"pages/page-{page_number:03d}.svg",
                    self._svg_markup(
                        title=f"{project.title} • {page_number}",
                        subtitle=f"Page {page_number}",
                    ),
                )
        return buffer.getvalue()

    def _write_artifact(self, *, job_id: uuid.UUID, filename: str, payload: bytes) -> Path:
        artifact_dir = Path(settings.export_artifact_dir)
        artifact_dir.mkdir(parents=True, exist_ok=True)
        target = artifact_dir / f"{job_id}-{filename}"
        target.write_bytes(payload)
        return target

    def _build_download_url(self, *, base_url: str, project_id: uuid.UUID, job_id: uuid.UUID) -> str:
        expires_at = datetime.now(UTC) + timedelta(seconds=settings.export_download_token_ttl_seconds)
        token = jwt.encode(
            {
                "scope": "export_artifact",
                "project_id": str(project_id),
                "job_id": str(job_id),
                "exp": int(expires_at.timestamp()),
            },
            settings.auth_jwt_secret,
            algorithm=settings.auth_jwt_algorithm,
        )
        return f"{base_url}/v1/projects/{project_id}/exports/{job_id}/artifact?token={token}"

    def _validate_download_token(self, *, token: str, project_id: uuid.UUID, job_id: uuid.UUID) -> None:
        try:
            payload = jwt.decode(
                token,
                settings.auth_jwt_secret,
                algorithms=[settings.auth_jwt_algorithm],
            )
        except jwt.InvalidTokenError as exc:
            raise DomainError(
                code="INVALID_EXPORT_TOKEN",
                message="Invalid export download token.",
                status_code=403,
            ) from exc

        if (
            payload.get("scope") != "export_artifact"
            or payload.get("project_id") != str(project_id)
            or payload.get("job_id") != str(job_id)
        ):
            raise DomainError(
                code="INVALID_EXPORT_TOKEN",
                message="Invalid export download token.",
                status_code=403,
            )

    @staticmethod
    def _artifact_media_type(export_type: ExportType) -> str:
        if export_type == ExportType.PDF:
            return "application/pdf"
        return "application/zip"

    @staticmethod
    def _project_title_slug(title: str) -> str:
        normalized = "".join(char.lower() if char.isalnum() else "-" for char in title).strip("-")
        compact = "-".join(part for part in normalized.split("-") if part)
        return compact or "storycomicai-project"

    @staticmethod
    def _svg_markup(*, title: str, subtitle: str) -> str:
        safe_title = ExportService._escape_xml(title)
        safe_subtitle = ExportService._escape_xml(subtitle)
        return (
            "<svg xmlns='http://www.w3.org/2000/svg' width='1536' height='2048' viewBox='0 0 1536 2048'>"
            "<rect width='1536' height='2048' fill='#111418'/>"
            "<rect x='80' y='80' width='1376' height='1888' rx='42' fill='#F3F0E8'/>"
            "<text x='768' y='930' text-anchor='middle' font-size='88' font-family='Helvetica' fill='#111418'>"
            f"{safe_title}</text>"
            "<text x='768' y='1040' text-anchor='middle' font-size='42' font-family='Helvetica' fill='#5A5F68'>"
            f"{safe_subtitle}</text>"
            "</svg>"
        )

    @staticmethod
    def _escape_xml(value: str) -> str:
        return (
            value.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;")
        )

    @staticmethod
    def _pdf_text_stream(lines: list[str]) -> bytes:
        y = 760
        commands = ["BT", "/F1 26 Tf", "72 0 0 1 72 760 Tm"]
        for index, line in enumerate(lines):
            safe_line = (
                line.replace("\\", "\\\\")
                .replace("(", "\\(")
                .replace(")", "\\)")
            )
            if index == 0:
                commands.append(f"({safe_line}) Tj")
            else:
                y -= 32
                commands.append(f"72 0 0 1 72 {y} Tm")
                commands.append(f"({safe_line}) Tj")
        commands.append("ET")
        return "\n".join(commands).encode("utf-8")

    @staticmethod
    def _minimal_pdf(content_stream: bytes) -> bytes:
        stream_length = len(content_stream)
        objects = [
            b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
            b"2 0 obj\n<< /Type /Pages /Count 1 /Kids [3 0 R] >>\nendobj\n",
            (
                b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
                b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n"
            ),
            b"4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n",
            (
                f"5 0 obj\n<< /Length {stream_length} >>\nstream\n".encode("utf-8")
                + content_stream
                + b"\nendstream\nendobj\n"
            ),
        ]
        header = b"%PDF-1.4\n"
        body = bytearray(header)
        offsets = [0]
        for obj in objects:
            offsets.append(len(body))
            body.extend(obj)
        xref_offset = len(body)
        xref = [f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode("utf-8")]
        xref.extend(f"{offset:010d} 00000 n \n".encode("utf-8") for offset in offsets[1:])
        trailer = (
            f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF\n"
        ).encode("utf-8")
        body.extend(b"".join(xref))
        body.extend(trailer)
        return bytes(body)


def run_export_job(job_id: str, project_id: str | None = None) -> None:
    """Worker-facing entrypoint for export generation."""

    del project_id
    ExportService().run_export_job(job_id=uuid.UUID(job_id))
