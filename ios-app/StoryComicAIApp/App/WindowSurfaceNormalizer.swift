import SwiftUI
import UIKit

struct WindowSurfaceNormalizer: UIViewRepresentable {
    func makeUIView(context: Context) -> SurfaceProbeView {
        SurfaceProbeView()
    }

    func updateUIView(_ uiView: SurfaceProbeView, context: Context) {
        uiView.scheduleNormalization()
    }
}

final class SurfaceProbeView: UIView {
    private var hasLoggedHierarchy = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scheduleNormalization()
    }

    func scheduleNormalization() {
        DispatchQueue.main.async { [weak self] in
            self?.normalizeWindowSurface()
        }
    }

    private func normalizeWindowSurface() {
        guard let window else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.normalizeWindowSurface()
            }
            return
        }

        let surfaceColor = UIColor(AppColor.backgroundPrimary)
        window.backgroundColor = surfaceColor
        window.isOpaque = true

        if let rootView = window.rootViewController?.view {
            normalize(view: rootView, surfaceColor: surfaceColor, windowBounds: window.bounds)

            var ancestor = rootView.superview
            while let current = ancestor {
                normalize(view: current, surfaceColor: surfaceColor, windowBounds: window.bounds)
                ancestor = current.superview
            }
        }

        window.subviews.forEach { normalize(view: $0, surfaceColor: surfaceColor, windowBounds: window.bounds) }

        if !hasLoggedHierarchy {
            hasLoggedHierarchy = true
            logHierarchy(for: window)
        }
    }

    private func shouldReplaceBackgroundColor(_ color: UIColor?) -> Bool {
        guard let color else { return true }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return true
        }

        let isTransparent = alpha < 0.05
        let isNearlyBlack = red < 0.08 && green < 0.08 && blue < 0.08
        return isTransparent || isNearlyBlack
    }

    private func normalize(view: UIView, surfaceColor: UIColor, windowBounds: CGRect) {
        if shouldReplaceBackgroundColor(view.backgroundColor) {
            view.backgroundColor = surfaceColor
        }

        let widthRatio = windowBounds.width == 0 ? 0 : view.bounds.width / windowBounds.width
        let heightRatio = windowBounds.height == 0 ? 0 : view.bounds.height / windowBounds.height
        let isLargeContainer = widthRatio > 0.84 && heightRatio > 0.84

        if isLargeContainer {
            view.layer.cornerRadius = 0
            view.layer.maskedCorners = []
            view.layer.masksToBounds = false
            view.clipsToBounds = false
        }
    }

    private func logHierarchy(for window: UIWindow) {
        NSLog("[StoryComicAI][Window] frame=%@ bounds=%@ level=%f root=%@",
              NSCoder.string(for: window.frame),
              NSCoder.string(for: window.bounds),
              window.windowLevel.rawValue,
              String(describing: type(of: window.rootViewController)))

        var current = window.rootViewController?.view
        var index = 0
        while let view = current, index < 8 {
            NSLog("[StoryComicAI][View %d] class=%@ frame=%@ bounds=%@ corner=%.2f clips=%@ bg=%@",
                  index,
                  String(describing: type(of: view)),
                  NSCoder.string(for: view.frame),
                  NSCoder.string(for: view.bounds),
                  view.layer.cornerRadius,
                  view.clipsToBounds.description,
                  String(describing: view.backgroundColor))
            current = view.superview
            index += 1
        }
    }
}
