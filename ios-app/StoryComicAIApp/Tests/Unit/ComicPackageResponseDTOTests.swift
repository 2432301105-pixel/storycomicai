import XCTest
@testable import StoryComicAIApp

final class ComicPackageResponseDTOTests: XCTestCase {
    func testDecodesLegacyRevealMetadataFromOldKey() throws {
        let payload = """
        {
          "project_id": "11111111-1111-1111-1111-111111111111",
          "title": "Story",
          "pages": [],
          "reveal_metadata": {
            "headline": "Legacy Headline",
            "subheadline": "Legacy Subheadline",
            "personalization_tag": "hero",
            "generated_at_utc": "2026-03-29T16:00:00Z"
          }
        }
        """.data(using: .utf8)!

        let dto = try APICoding.decoder.decode(ComicBookPackageResponseDTO.self, from: payload)

        XCTAssertEqual(dto.legacyRevealMetadata?.headline, "Legacy Headline")
        XCTAssertEqual(dto.legacyRevealMetadata?.subheadline, "Legacy Subheadline")
    }

    func testDecodesLegacyRevealMetadataFromNewKey() throws {
        let payload = """
        {
          "project_id": "11111111-1111-1111-1111-111111111111",
          "title": "Story",
          "pages": [],
          "legacy_reveal_metadata": {
            "headline": "New Headline",
            "subheadline": "New Subheadline",
            "personalization_tag": "hero",
            "generated_at_utc": "2026-03-29T16:00:00Z"
          }
        }
        """.data(using: .utf8)!

        let dto = try APICoding.decoder.decode(ComicBookPackageResponseDTO.self, from: payload)

        XCTAssertEqual(dto.legacyRevealMetadata?.headline, "New Headline")
        XCTAssertEqual(dto.legacyRevealMetadata?.subheadline, "New Subheadline")
    }

    func testDecodesPreviewPagesAsArrayCountForBackwardCompatibility() throws {
        let payload = """
        {
          "project_id": "11111111-1111-1111-1111-111111111111",
          "title": "Story",
          "pages": [],
          "preview_pages": [
            "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            "cccccccc-cccc-cccc-cccc-cccccccccccc"
          ]
        }
        """.data(using: .utf8)!

        let dto = try APICoding.decoder.decode(ComicBookPackageResponseDTO.self, from: payload)

        XCTAssertEqual(dto.previewPages, 3)
    }
}
