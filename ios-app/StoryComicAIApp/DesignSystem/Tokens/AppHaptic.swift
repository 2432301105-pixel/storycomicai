import UIKit

enum AppHapticToken {
    case revealIntro
    case pageTurn
    case modeSwitch
    case confirm
}

protocol HapticProviding {
    func trigger(_ token: AppHapticToken)
}

final class SystemHapticProvider: HapticProviding {
    private let revealGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let pageTurnGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func trigger(_ token: AppHapticToken) {
        if UIAccessibility.isReduceMotionEnabled && (token == .revealIntro || token == .pageTurn) {
            return
        }

        switch token {
        case .revealIntro:
            revealGenerator.prepare()
            revealGenerator.impactOccurred()
        case .pageTurn:
            pageTurnGenerator.prepare()
            pageTurnGenerator.impactOccurred(intensity: 0.7)
        case .modeSwitch:
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        case .confirm:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        }
    }
}

final class NoopHapticProvider: HapticProviding {
    func trigger(_ token: AppHapticToken) {
        _ = token
    }
}
