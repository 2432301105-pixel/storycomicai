import XCTest
@testable import StoryComicAIApp

@MainActor
final class StyleSelectionViewModelTests: XCTestCase {
    func testEnsureProjectExistsCreatesProjectWhenMissing() async {
        let projectService = MockProjectServiceForTests()
        let viewModel = StyleSelectionViewModel(projectService: projectService)
        let flowStore = CreateProjectFlowStore()
        flowStore.projectName = "My Story"
        flowStore.selectedStyle = .manga

        let success = await viewModel.ensureProjectExists(for: flowStore)

        XCTAssertTrue(success)
        XCTAssertNotNil(flowStore.createdProject)
    }

    func testEnsureProjectExistsFailsForInvalidProjectName() async {
        let projectService = MockProjectServiceForTests()
        let viewModel = StyleSelectionViewModel(projectService: projectService)
        let flowStore = CreateProjectFlowStore()
        flowStore.projectName = "  "
        flowStore.selectedStyle = .cinematic

        let success = await viewModel.ensureProjectExists(for: flowStore)

        XCTAssertFalse(success)
        XCTAssertNil(flowStore.createdProject)
    }
}
