import Foundation

final class MockAPIClient: APIClient {
    private let store = MockBackendStore()

    func request<T: Decodable>(_ endpoint: APIEndpoint, decode: T.Type) async throws -> T {
        switch (endpoint.method, endpoint.path) {
        case (.post, "/v1/auth/apple/verify"):
            return try await decodeOutput(
                AuthTokenResponseDTO(
                    userID: UUID(),
                    accessToken: "mock_access_token_\(UUID().uuidString)",
                    tokenType: "bearer",
                    expiresInSeconds: 7200,
                    issuedAtUTC: Date()
                ),
                as: decode
            )

        case (.post, "/v1/projects"):
            let payload = try decodeInput(CreateProjectRequestBody.self, from: endpoint.body)
            let created = await store.createProject(payload)
            return try await decodeOutput(created, as: decode)

        case (.get, "/v1/projects"):
            let projects = await store.listProjects()
            return try await decodeOutput(projects, as: decode)

        default:
            return try await routeNestedEndpoints(endpoint, decode: decode)
        }
    }

    private func routeNestedEndpoints<T: Decodable>(_ endpoint: APIEndpoint, decode: T.Type) async throws -> T {
        let parts = endpoint.path.split(separator: "/")
        // /v1/projects/{projectID}/photos/presign
        if parts.count == 5,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .post,
           parts[3] == "photos",
           parts[4] == "presign",
           let projectID = UUID(uuidString: String(parts[2])) {
            let payload = try decodeInput(PhotoPresignRequestBody.self, from: endpoint.body)
            let presigned = await store.presignPhoto(projectID: projectID, payload: payload)
            return try await decodeOutput(presigned, as: decode)
        }

        // /v1/projects/{projectID}/photos/complete
        if parts.count == 5,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .post,
           parts[3] == "photos",
           parts[4] == "complete",
           let projectID = UUID(uuidString: String(parts[2])) {
            let payload = try decodeInput(PhotoCompleteRequestBody.self, from: endpoint.body)
            let completed = await store.completePhoto(projectID: projectID, payload: payload)
            return try await decodeOutput(completed, as: decode)
        }

        // /v1/projects/{projectID}/hero-preview
        if parts.count == 4,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .post,
           parts[3] == "hero-preview",
           let projectID = UUID(uuidString: String(parts[2])) {
            let payload = try decodeInput(HeroPreviewStartRequestBody.self, from: endpoint.body)
            let started = await store.startHeroPreview(projectID: projectID, payload: payload)
            return try await decodeOutput(started, as: decode)
        }

        // /v1/projects/{projectID}/comic-package
        if parts.count == 4,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .get,
           parts[3] == "comic-package",
           let projectID = UUID(uuidString: String(parts[2])) {
            let package = await store.comicPackage(projectID: projectID)
            return try await decodeOutput(package, as: decode)
        }

        // /v1/projects/{projectID}/reading-progress
        if parts.count == 4,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .patch,
           parts[3] == "reading-progress",
           let projectID = UUID(uuidString: String(parts[2])) {
            let payload = try decodeInput(ReadingProgressUpdateRequestBody.self, from: endpoint.body)
            let progress = await store.updateReadingProgress(projectID: projectID, payload: payload)
            return try await decodeOutput(progress, as: decode)
        }

        // /v1/projects/{projectID}/exports
        if parts.count == 4,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .post,
           parts[3] == "exports",
           let projectID = UUID(uuidString: String(parts[2])) {
            let payload = try decodeInput(CreateExportRequestBody.self, from: endpoint.body)
            let export = await store.createExport(projectID: projectID, payload: payload)
            return try await decodeOutput(export, as: decode)
        }

        // /v1/projects/{projectID}/exports/{jobID}
        if parts.count == 5,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .get,
           parts[3] == "exports",
           let projectID = UUID(uuidString: String(parts[2])),
           let jobID = UUID(uuidString: String(parts[4])) {
            let status = await store.exportStatus(projectID: projectID, jobID: jobID)
            return try await decodeOutput(status, as: decode)
        }

        // /v1/projects/{projectID}/hero-preview/{jobID}
        if parts.count == 5,
           parts[0] == "v1",
           parts[1] == "projects",
           endpoint.method == .get,
           parts[3] == "hero-preview",
           let projectID = UUID(uuidString: String(parts[2])),
           let jobID = UUID(uuidString: String(parts[4])) {
            let status = await store.heroPreviewStatus(projectID: projectID, jobID: jobID)
            return try await decodeOutput(status, as: decode)
        }

        throw APIError.backend(code: "MOCK_ENDPOINT_NOT_IMPLEMENTED", message: "Mock endpoint not implemented: \(endpoint.path)")
    }

    private func decodeInput<T: Decodable>(_ type: T.Type, from data: Data?) throws -> T {
        guard let data else {
            throw APIError.backend(code: "MOCK_INVALID_INPUT", message: "Request body is missing.")
        }
        do {
            return try APICoding.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }

    private func decodeOutput<T: Decodable>(_ value: some Encodable, as type: T.Type) async throws -> T {
        let data = try APICoding.encoder.encode(value)
        return try APICoding.decoder.decode(T.self, from: data)
    }
}

actor MockBackendStore {
    private var projects: [ProjectResponseDTO] = []
    private var heroJobs: [UUID: HeroPreviewStatusResponseDTO] = [:]
    private var heroPollCount: [UUID: Int] = [:]
    private var readingProgressByProject: [UUID: ComicReadingProgressResponseDTO] = [:]
    private var exportJobs: [UUID: MockExportJobRecord] = [:]
    private var exportPollCount: [UUID: Int] = [:]

    func createProject(_ payload: CreateProjectRequestBody) -> ProjectResponseDTO {
        let now = Date()
        let dto = ProjectResponseDTO(
            id: UUID(),
            title: payload.title,
            style: payload.style,
            targetPages: payload.targetPages,
            freePreviewPages: 3,
            status: "draft",
            isUnlocked: true,
            createdAtUTC: now,
            updatedAtUTC: now
        )
        projects.insert(dto, at: 0)
        readingProgressByProject[dto.id] = ComicReadingProgressResponseDTO(
            currentPageIndex: 0,
            lastOpenedAtUTC: nil
        )
        return dto
    }

    func listProjects() -> ProjectListResponseDTO {
        ProjectListResponseDTO(items: projects, nextCursor: nil)
    }

    func presignPhoto(projectID: UUID, payload: PhotoPresignRequestBody) -> PhotoPresignResponseDTO {
        let photoID = UUID()
        return PhotoPresignResponseDTO(
            photoID: photoID,
            uploadURL: URL(string: "https://mock.storycomicai.local/upload/\(photoID.uuidString)")!,
            storageKey: "projects/\(projectID.uuidString)/photos/\(payload.filename)",
            expiresInSeconds: 900
        )
    }

    func completePhoto(projectID: UUID, payload: PhotoCompleteRequestBody) -> PhotoCompleteResponseDTO {
        _ = projectID
        return PhotoCompleteResponseDTO(photoID: payload.photoID, status: "validated", qualityScore: 0.94)
    }

    func startHeroPreview(projectID: UUID, payload: HeroPreviewStartRequestBody) -> HeroPreviewStartResponseDTO {
        _ = payload
        let jobID = UUID()
        heroPollCount[jobID] = 0
        heroJobs[jobID] = HeroPreviewStatusResponseDTO(
            jobID: jobID,
            projectID: projectID,
            status: "queued",
            currentStage: "queued",
            progressPct: 5,
            result: nil,
            errorMessage: nil
        )
        return HeroPreviewStartResponseDTO(jobID: jobID, status: "queued", currentStage: "queued")
    }

    func heroPreviewStatus(projectID: UUID, jobID: UUID) -> HeroPreviewStatusResponseDTO {
        let count = (heroPollCount[jobID] ?? 0) + 1
        heroPollCount[jobID] = count

        let nextStatus: HeroPreviewStatusResponseDTO
        if count < 2 {
            nextStatus = HeroPreviewStatusResponseDTO(
                jobID: jobID,
                projectID: projectID,
                status: "running",
                currentStage: "rendering_preview",
                progressPct: 35,
                result: nil,
                errorMessage: nil
            )
        } else if count < 4 {
            nextStatus = HeroPreviewStatusResponseDTO(
                jobID: jobID,
                projectID: projectID,
                status: "running",
                currentStage: "refining",
                progressPct: 75,
                result: nil,
                errorMessage: nil
            )
        } else {
            nextStatus = HeroPreviewStatusResponseDTO(
                jobID: jobID,
                projectID: projectID,
                status: "succeeded",
                currentStage: "completed",
                progressPct: 100,
                result: HeroPreviewResultDTO(
                    heroSheetVersion: 1,
                    style: "manga",
                    previewAssets: HeroPreviewAssetURLsDTO(
                        front: URL(string: "https://mock.storycomicai.local/hero/\(jobID.uuidString)/front.png"),
                        threeQuarter: URL(string: "https://mock.storycomicai.local/hero/\(jobID.uuidString)/three_quarter.png"),
                        side: URL(string: "https://mock.storycomicai.local/hero/\(jobID.uuidString)/side.png")
                    ),
                    consistencySeed: UUID().uuidString
                ),
                errorMessage: nil
            )
        }

        heroJobs[jobID] = nextStatus
        return nextStatus
    }

    func comicPackage(projectID: UUID) -> ComicBookPackageResponseDTO {
        let project = projects.first { $0.id == projectID }
        let fallbackPackage = MockFixtures.sampleComicBookPackage(projectID: projectID, source: .mock)

        let basePackage: ComicBookPackage
        if let project {
            let isUnlocked = project.isUnlocked
            basePackage = ComicBookPackage(
                projectID: projectID,
                title: project.title,
                subtitle: "A personalized \(project.style.displayName.lowercased()) comic edition",
                styleLabel: project.style.displayName,
                cover: fallbackPackage.cover,
                pages: fallbackPackage.pages,
                previewPageCount: project.freePreviewPages,
                presentationHints: fallbackPackage.presentationHints,
                exportAvailability: ComicExportAvailability(
                    isPDFAvailable: isUnlocked,
                    pdfURL: nil,
                    isImagePackAvailable: isUnlocked,
                    lockedByPaywall: !isUnlocked
                ),
                paywallMetadata: ComicPaywallMetadata(
                    isUnlocked: isUnlocked,
                    lockReason: isUnlocked ? nil : "preview_limit",
                    offers: fallbackPackage.paywallMetadata.offers
                ),
                ctaMetadata: fallbackPackage.ctaMetadata,
                readingProgress: readingProgressByProject[projectID].map {
                    ComicReadingProgress(
                        currentPageIndex: $0.currentPageIndex,
                        lastOpenedAtUTC: $0.lastOpenedAtUTC
                    )
                } ?? fallbackPackage.readingProgress,
                legacyRevealMetadata: fallbackPackage.legacyRevealMetadata,
                source: .mock
            )
        } else {
            basePackage = fallbackPackage
        }

        return ComicBookPackageResponseDTO(
            projectID: basePackage.projectID,
            title: basePackage.title,
            subtitle: basePackage.subtitle,
            styleLabel: basePackage.styleLabel,
            cover: ComicCoverResponseDTO(
                imageURL: basePackage.cover.imageURL,
                titleText: basePackage.cover.titleText,
                subtitleText: basePackage.cover.subtitleText,
                focalPoint: nil
            ),
            pages: basePackage.pages.map { page in
                ComicPageResponseDTO(
                    id: page.id,
                    pageNumber: page.pageNumber,
                    title: page.title,
                    caption: page.caption,
                    thumbnailURL: page.thumbnailURL,
                    fullImageURL: page.fullImageURL,
                    width: nil,
                    height: nil
                )
            },
            previewPages: basePackage.previewPageCount,
            presentationHints: ComicPresentationHintsResponseDTO(
                readingDirection: basePackage.presentationHints.readingDirection.rawValue,
                preferredRevealMode: basePackage.presentationHints.preferredRevealMode,
                deskTheme: basePackage.presentationHints.deskTheme.rawValue,
                accentHex: basePackage.presentationHints.accentHex,
                motionProfile: "standard",
                extra: basePackage.presentationHints.extra
            ),
            exportAvailability: ComicExportAvailabilityResponseDTO(
                isPDFAvailable: basePackage.exportAvailability.isPDFAvailable,
                pdfURL: basePackage.exportAvailability.pdfURL,
                isImagePackAvailable: basePackage.exportAvailability.isImagePackAvailable,
                lockedByPaywall: basePackage.exportAvailability.lockedByPaywall
            ),
            paywallMetadata: ComicPaywallMetadataResponseDTO(
                isUnlocked: basePackage.paywallMetadata.isUnlocked,
                lockReason: basePackage.paywallMetadata.lockReason,
                offers: basePackage.paywallMetadata.offers.map {
                    ComicPaywallOfferResponseDTO(
                        offerID: $0.id,
                        price: $0.price,
                        currency: $0.currency,
                        priority: $0.priority,
                        isRecommended: $0.isRecommended,
                        badgeLabel: $0.badgeLabel
                    )
                }
            ),
            readingProgress: ComicReadingProgressResponseDTO(
                currentPageIndex: basePackage.readingProgress.currentPageIndex,
                lastOpenedAtUTC: basePackage.readingProgress.lastOpenedAtUTC
            ),
            ctaMetadata: ComicCTAMetadataResponseDTO(
                revealHeadline: basePackage.ctaMetadata.revealHeadline,
                revealSubheadline: basePackage.ctaMetadata.revealSubheadline,
                revealPrimaryLabel: basePackage.ctaMetadata.revealPrimaryLabel,
                revealSecondaryLabel: basePackage.ctaMetadata.revealSecondaryLabel,
                exportLabel: basePackage.ctaMetadata.exportLabel
            ),
            legacyRevealMetadata: basePackage.legacyRevealMetadata.map {
                ComicRevealMetadataResponseDTO(
                    headline: $0.headline,
                    subheadline: $0.subheadline,
                    personalizationTag: $0.personalizationTag,
                    generatedAtUTC: $0.generatedAtUTC
                )
            }
        )
    }

    func updateReadingProgress(
        projectID: UUID,
        payload: ReadingProgressUpdateRequestBody
    ) -> ComicReadingProgressResponseDTO {
        let updated = ComicReadingProgressResponseDTO(
            currentPageIndex: max(0, payload.currentPageIndex),
            lastOpenedAtUTC: payload.lastOpenedAtUTC
        )
        readingProgressByProject[projectID] = updated
        return updated
    }

    func createExport(
        projectID: UUID,
        payload: CreateExportRequestBody
    ) -> ExportJobCreateResponseDTO {
        let jobID = UUID()
        let now = Date()

        let artifactSuffix: String = {
            switch payload.type {
            case .pdf:
                return "pdf"
            case .imageBundle:
                return "zip"
            }
        }()

        let artifactURL = URL(
            string: "https://mock.storycomicai.local/exports/\(projectID.uuidString)/\(jobID.uuidString).\(artifactSuffix)"
        )

        exportJobs[jobID] = MockExportJobRecord(
            jobID: jobID,
            projectID: projectID,
            type: payload.type,
            createdAtUTC: now,
            artifactURL: artifactURL
        )
        exportPollCount[jobID] = 0

        return ExportJobCreateResponseDTO(
            jobID: jobID,
            projectID: projectID,
            type: payload.type,
            status: .queued
        )
    }

    func exportStatus(projectID: UUID, jobID: UUID) -> ExportJobStatusResponseDTO {
        let pollCount = (exportPollCount[jobID] ?? 0) + 1
        exportPollCount[jobID] = pollCount

        guard let record = exportJobs[jobID] else {
            return ExportJobStatusResponseDTO(
                jobID: jobID,
                projectID: projectID,
                type: .pdf,
                status: .failed,
                progressPct: nil,
                artifactURL: nil,
                errorCode: "EXPORT_NOT_FOUND",
                errorMessage: "Mock export job not found.",
                retryable: false
            )
        }

        if pollCount < 2 {
            return ExportJobStatusResponseDTO(
                jobID: record.jobID,
                projectID: record.projectID,
                type: record.type,
                status: .queued,
                progressPct: 5,
                artifactURL: nil,
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        } else if pollCount < 5 {
            return ExportJobStatusResponseDTO(
                jobID: record.jobID,
                projectID: record.projectID,
                type: record.type,
                status: .running,
                progressPct: min(95, 20 + (pollCount * 18)),
                artifactURL: nil,
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        } else {
            return ExportJobStatusResponseDTO(
                jobID: record.jobID,
                projectID: record.projectID,
                type: record.type,
                status: .succeeded,
                progressPct: 100,
                artifactURL: record.artifactURL,
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        }
    }
}

private struct MockExportJobRecord {
    let jobID: UUID
    let projectID: UUID
    let type: ComicExportType
    let createdAtUTC: Date
    let artifactURL: URL?
}
