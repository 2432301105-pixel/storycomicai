import Foundation

struct AppContainer {
    let configuration: AppConfiguration
    let tokenStore: AccessTokenStore

    let apiClient: any APIClient

    let authService: any AuthService
    let projectService: any ProjectService
    let uploadService: any UploadService
    let heroPreviewService: any HeroPreviewService
    let comicPackageService: any ComicPackageService
    let comicGenerationService: any ComicGenerationService
    let readerAssetPrefetcher: any ReaderAssetPrefetching
    let exportService: any ExportService
    let analyticsService: any AnalyticsService

    static func live(configuration: AppConfiguration = .resolve()) -> AppContainer {
        let tokenStore = KeychainAccessTokenStore()
        let environment = APIEnvironment(baseURL: configuration.apiBaseURL, timeout: 30)

        let apiClient: any APIClient
        if configuration.useMockServices {
            apiClient = MockAPIClient()
        } else {
            apiClient = LiveAPIClient(environment: environment, tokenStore: tokenStore)
        }

        let authService = DefaultAuthService(apiClient: apiClient)
        let projectService = DefaultProjectService(apiClient: apiClient)
        let uploadTransferClient: any UploadTransferClient = configuration.useMockServices
            ? MockUploadTransferClient()
            : LiveUploadTransferClient()
        let uploadService = DefaultUploadService(apiClient: apiClient, transferClient: uploadTransferClient)
        let heroPreviewService = DefaultHeroPreviewService(apiClient: apiClient)
        let comicPackageService = DefaultComicPackageService(apiClient: apiClient)
        let comicGenerationService = DefaultComicGenerationService(apiClient: apiClient)
        let analyticsService = ConsoleAnalyticsService()
        let readerTelemetry = AnalyticsReaderPerformanceTelemetry(
            analyticsService: analyticsService,
            samplingRate: 0.2
        )
        let imagePipeline = ReaderImagePipeline.shared
        Task {
            await imagePipeline.setTelemetry(readerTelemetry)
        }
        let readerAssetPrefetcher = DefaultReaderAssetPrefetcher(
            cachePolicy: .standard(),
            imagePipeline: imagePipeline,
            telemetry: readerTelemetry
        )
        let exportService = DefaultExportService(apiClient: apiClient)

        return AppContainer(
            configuration: configuration,
            tokenStore: tokenStore,
            apiClient: apiClient,
            authService: authService,
            projectService: projectService,
            uploadService: uploadService,
            heroPreviewService: heroPreviewService,
            comicPackageService: comicPackageService,
            comicGenerationService: comicGenerationService,
            readerAssetPrefetcher: readerAssetPrefetcher,
            exportService: exportService,
            analyticsService: analyticsService
        )
    }

    static func preview() -> AppContainer {
        let configuration = AppConfiguration(
            apiBaseURL: URL(string: "http://localhost:8000")!,
            useMockServices: true,
            heroPreviewPollingIntervalSeconds: 1,
            launchesDirectlyIntoApp: true,
            launchIdentityTokenSeed: "preview-launch-user",
            appleClientID: "com.storycomicai.app"
        )
        return .live(configuration: configuration)
    }
}
