import SwiftUI

enum AppElevation {
    enum Surface {
        static let radius: CGFloat = 22
        static let shadowRadius: CGFloat = 18
        static let shadowYOffset: CGFloat = 8
    }

    enum Book {
        static let revealRadius: CGFloat = 32
        static let revealYOffset: CGFloat = 16
        static let pageRadius: CGFloat = 24
        static let pageYOffset: CGFloat = 14
        static let coverCorner: CGFloat = 22
        static let pageCorner: CGFloat = 8
    }
}
