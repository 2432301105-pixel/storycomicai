import Foundation

enum ComicPresentationMode: String, CaseIterable, Hashable, Identifiable {
    case reveal
    case preview
    case flatReader
    case export

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reveal:
            return "Reveal"
        case .preview:
            return "Book"
        case .flatReader:
            return "Reader"
        case .export:
            return "Export"
        }
    }

    static var switchableModes: [ComicPresentationMode] {
        [.preview, .flatReader, .export]
    }
}
