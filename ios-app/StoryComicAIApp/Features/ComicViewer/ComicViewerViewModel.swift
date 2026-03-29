import Foundation

@MainActor
final class ComicViewerViewModel: ObservableObject {
    @Published private(set) var pages: [ComicPage] = MockFixtures.sampleComicPages()
}
