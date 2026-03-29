import SwiftUI

enum AppMotion {
    private enum Duration {
        static let revealEntry: Double = 0.6
        static let revealContent: Double = 0.35
        static let pageTurnResponse: Double = 0.32
        static let modeSwitch: Double = 0.2
    }

    private static let reducedMotionDuration: Double = 0.01

    static func revealEntry(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: reducedMotionDuration)
            : .easeOut(duration: Duration.revealEntry)
    }

    static func revealContent(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: reducedMotionDuration)
            : .easeInOut(duration: Duration.revealContent)
    }

    static func pageTurn(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: reducedMotionDuration)
            : .interactiveSpring(
                response: Duration.pageTurnResponse,
                dampingFraction: 0.86,
                blendDuration: 0.12
            )
    }

    static func modeSwitch(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: reducedMotionDuration)
            : .easeInOut(duration: Duration.modeSwitch)
    }
}
