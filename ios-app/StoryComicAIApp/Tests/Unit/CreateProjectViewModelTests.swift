import XCTest
@testable import StoryComicAIApp

@MainActor
final class CreateProjectViewModelTests: XCTestCase {
    func testValidateProjectNameRejectsShortValue() {
        let viewModel = CreateProjectViewModel()

        let isValid = viewModel.validateProjectName("ab")

        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.validationMessage)
    }

    func testValidateProjectNameAcceptsValidValue() {
        let viewModel = CreateProjectViewModel()

        let isValid = viewModel.validateProjectName("Night Runner")

        XCTAssertTrue(isValid)
        XCTAssertNil(viewModel.validationMessage)
    }
}
