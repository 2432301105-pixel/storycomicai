import XCTest
@testable import StoryComicAIApp

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testLoadProjectsPopulatesLoadedState() async {
        let mockService = MockProjectServiceForTests()
        mockService.listResult = MockFixtures.sampleProjects()

        let viewModel = LibraryViewModel(projectService: mockService)
        await viewModel.loadProjects()

        switch viewModel.state {
        case let .loaded(projects):
            XCTAssertEqual(projects.count, mockService.listResult.count)
            XCTAssertEqual(projects.first?.title, mockService.listResult.first?.title)
        default:
            XCTFail("Expected loaded state")
        }
    }
}
