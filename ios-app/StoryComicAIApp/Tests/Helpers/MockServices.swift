import Foundation
@testable import StoryComicAIApp

final class MockProjectServiceForTests: ProjectService {
    var createResult: Project?
    var listResult: [Project] = []

    func createProject(title: String, storyText: String, style: StoryStyle, targetPages: Int) async throws -> Project {
        if let createResult { return createResult }
        return Project(
            id: UUID(),
            title: title,
            storyText: storyText,
            style: style,
            targetPages: targetPages,
            freePreviewPages: 3,
            status: "draft",
            isUnlocked: false,
            createdAtUTC: Date(),
            updatedAtUTC: Date()
        )
    }

    func listProjects(limit: Int) async throws -> [Project] {
        Array(listResult.prefix(limit))
    }
}

final class MockHeroPreviewServiceForTests: HeroPreviewService {
    var startResult = HeroPreviewJob(
        jobID: UUID(),
        projectID: UUID(),
        status: .queued,
        currentStage: "queued",
        progressPercent: 0,
        previewAssets: nil,
        errorMessage: nil
    )

    var statusSequence: [HeroPreviewJob] = []

    func startHeroPreview(projectID: UUID, photoIDs: [UUID], style: StoryStyle?) async throws -> HeroPreviewJob {
        _ = (photoIDs, style)
        return HeroPreviewJob(
            jobID: startResult.jobID,
            projectID: projectID,
            status: startResult.status,
            currentStage: startResult.currentStage,
            progressPercent: startResult.progressPercent,
            previewAssets: nil,
            errorMessage: nil
        )
    }

    func fetchHeroPreviewStatus(projectID: UUID, jobID: UUID) async throws -> HeroPreviewJob {
        _ = (projectID, jobID)
        if !statusSequence.isEmpty {
            return statusSequence.removeFirst()
        }
        return HeroPreviewJob(
            jobID: jobID,
            projectID: projectID,
            status: .succeeded,
            currentStage: "completed",
            progressPercent: 100,
            previewAssets: nil,
            errorMessage: nil
        )
    }
}

final class MockComicPackageServiceForTests: ComicPackageService {
    var package: ComicBookPackage = MockFixtures.sampleComicBookPackage(projectID: UUID(), source: .mock)
    var generationBlueprint: ComicGenerationBlueprint?
    private(set) var updateCalls: [(projectID: UUID, pageIndex: Int)] = []

    func fetchComicBookPackage(projectID: UUID) async throws -> ComicBookPackage {
        ComicBookPackage(
            projectID: projectID,
            title: package.title,
            subtitle: package.subtitle,
            styleLabel: package.styleLabel,
            cover: package.cover,
            pages: package.pages,
            previewPageCount: package.previewPageCount,
            presentationHints: package.presentationHints,
            exportAvailability: package.exportAvailability,
            paywallMetadata: package.paywallMetadata,
            ctaMetadata: package.ctaMetadata,
            readingProgress: package.readingProgress,
            legacyRevealMetadata: package.legacyRevealMetadata,
            generationBlueprint: package.generationBlueprint,
            source: package.source
        )
    }

    func fetchGenerationBlueprint(projectID: UUID) async throws -> ComicGenerationBlueprint {
        if let generationBlueprint {
            return generationBlueprint
        }
        return MockFixtures.sampleGenerationBlueprint(
            projectID: projectID,
            style: .cinematic,
            storyText: "A personalized comic is being generated from the story you wrote."
        )
    }

    func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) async throws -> ComicReadingProgress {
        _ = lastOpenedAtUTC
        updateCalls.append((projectID: projectID, pageIndex: currentPageIndex))
        return ComicReadingProgress(currentPageIndex: currentPageIndex, lastOpenedAtUTC: lastOpenedAtUTC)
    }
}

final class MockAnalyticsServiceForTests: AnalyticsService {
    private(set) var events: [(AnalyticsEvent, [String: String])] = []

    func track(event: AnalyticsEvent, properties: [String: String]) {
        events.append((event, properties))
    }
}

final class MockHapticProviderForTests: HapticProviding {
    private(set) var tokens: [AppHapticToken] = []

    func trigger(_ token: AppHapticToken) {
        tokens.append(token)
    }
}

actor NoopReaderAssetPrefetcherForTests: ReaderAssetPrefetching {
    func prefetch(pages: [ComicPresentationPage], around index: Int) async {
        _ = (pages, index)
    }

    func clear() async {}
}

final class MockExportServiceForTests: ExportService {
    private(set) var createCalls: Int = 0
    private(set) var statusCalls: Int = 0
    private(set) var downloadCalls: Int = 0

    var createError: Error?
    var statusError: Error?
    var downloadError: Error?
    var createErrors: [Error] = []
    var statusErrors: [Error] = []
    var downloadErrors: [Error] = []

    var createResult: ComicExportJob = ComicExportJob(
        jobID: UUID(),
        projectID: UUID(),
        type: .pdf,
        status: .queued,
        progressPct: nil,
        artifactURL: nil,
        errorCode: nil,
        errorMessage: nil,
        retryable: true
    )

    var statusSequence: [ComicExportJob] = []
    var downloadedURL: URL = URL(fileURLWithPath: "/tmp/storycomicai-test-export.pdf")

    func createExport(
        projectID: UUID,
        type: ComicExportType,
        preset: ComicExportPreset,
        includeCover: Bool
    ) async throws -> ComicExportJob {
        createCalls += 1
        if !createErrors.isEmpty {
            throw createErrors.removeFirst()
        }
        if let createError {
            throw createError
        }
        _ = (preset, includeCover)
        return ComicExportJob(
            jobID: createResult.jobID,
            projectID: projectID,
            type: type,
            status: createResult.status,
            progressPct: createResult.progressPct,
            artifactURL: createResult.artifactURL,
            errorCode: createResult.errorCode,
            errorMessage: createResult.errorMessage,
            retryable: createResult.retryable
        )
    }

    func getExportStatus(projectID: UUID, jobID: UUID) async throws -> ComicExportJob {
        statusCalls += 1
        if !statusErrors.isEmpty {
            throw statusErrors.removeFirst()
        }
        if let statusError {
            throw statusError
        }
        _ = (projectID, jobID)
        if !statusSequence.isEmpty {
            return statusSequence.removeFirst()
        }
        return ComicExportJob(
            jobID: jobID,
            projectID: projectID,
            type: .pdf,
            status: .succeeded,
            progressPct: 100,
            artifactURL: URL(string: "https://mock.storycomicai.local/exports/final.pdf"),
            errorCode: nil,
            errorMessage: nil,
            retryable: true
        )
    }

    func downloadArtifact(
        from remoteURL: URL,
        projectID: UUID,
        jobID: UUID,
        type: ComicExportType
    ) async throws -> URL {
        downloadCalls += 1
        if !downloadErrors.isEmpty {
            throw downloadErrors.removeFirst()
        }
        if let downloadError {
            throw downloadError
        }
        _ = (remoteURL, projectID, jobID, type)
        return downloadedURL
    }
}
