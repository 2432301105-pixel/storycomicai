import Foundation

struct ComicPage: Identifiable, Hashable {
    let id: UUID
    let pageNumber: Int
    let title: String
    let caption: String

    init(id: UUID = UUID(), pageNumber: Int, title: String, caption: String) {
        self.id = id
        self.pageNumber = pageNumber
        self.title = title
        self.caption = caption
    }
}
