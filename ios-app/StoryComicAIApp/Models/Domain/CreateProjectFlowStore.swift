import Foundation

@MainActor
final class CreateProjectFlowStore: ObservableObject {
    @Published var projectName: String = ""
    @Published var storyText: String = ""
    @Published var selectedStyle: StoryStyle = .manga

    @Published var selectedLocalPhotos: [LocalPhotoAsset] = []
    @Published var uploadedPhotoIDs: [UUID] = []

    @Published var createdProject: Project?
    @Published var heroPreviewJob: HeroPreviewJob?
    @Published var comicGenerationJob: ComicGenerationJob?

    var canStartHeroPreview: Bool {
        createdProject != nil && !uploadedPhotoIDs.isEmpty
    }
}
