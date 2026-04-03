import SwiftUI
import UIKit

enum ComicImageLoadStrategy {
    case thumbnailOnly
    case thumbnailThenFull
    case fullThenThumbnail
}

struct OptimizedComicImageView: View {
    let thumbnailURL: URL?
    let fullImageURL: URL?
    let strategy: ComicImageLoadStrategy
    let contentMode: ContentMode
    let thumbnailMaxPixelSize: CGFloat
    let fullMaxPixelSize: CGFloat
    let placeholderSystemImageName: String

    @Environment(\.displayScale) private var displayScale
    @StateObject private var viewModel: OptimizedComicImageViewModel

    init(
        thumbnailURL: URL?,
        fullImageURL: URL?,
        strategy: ComicImageLoadStrategy,
        contentMode: ContentMode = .fill,
        thumbnailMaxPixelSize: CGFloat = 720,
        fullMaxPixelSize: CGFloat = 1_600,
        placeholderSystemImageName: String = "photo",
        imagePipeline: ReaderImagePipeline = .shared
    ) {
        self.thumbnailURL = thumbnailURL
        self.fullImageURL = fullImageURL
        self.strategy = strategy
        self.contentMode = contentMode
        self.thumbnailMaxPixelSize = thumbnailMaxPixelSize
        self.fullMaxPixelSize = fullMaxPixelSize
        self.placeholderSystemImageName = placeholderSystemImageName
        _viewModel = StateObject(
            wrappedValue: OptimizedComicImageViewModel(imagePipeline: imagePipeline)
        )
    }

    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder
            }
        }
        .task(id: loadIdentity) {
            viewModel.load(
                thumbnailURL: thumbnailURL,
                fullImageURL: fullImageURL,
                strategy: strategy,
                displayScale: displayScale,
                thumbnailMaxPixelSize: thumbnailMaxPixelSize,
                fullMaxPixelSize: fullMaxPixelSize
            )
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }

    private var loadIdentity: String {
        [
            thumbnailURL?.absoluteString ?? "nil-thumb",
            fullImageURL?.absoluteString ?? "nil-full",
            "\(strategy)",
            "\(thumbnailMaxPixelSize)",
            "\(fullMaxPixelSize)"
        ].joined(separator: "|")
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColor.backgroundSecondary)
            ComicCharacterPlaceholderCard()
        }
    }
}

private struct ComicCharacterPlaceholderCard: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [AppColor.surfaceMuted, AppColor.pagePaper, AppColor.backgroundCanvas],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [AppColor.accentSecondary.opacity(0.34), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: proxy.size.width * 0.8
                )

                ForEach(0..<8, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(AppColor.accent.opacity(index.isMultiple(of: 2) ? 0.12 : 0.08))
                        .frame(width: proxy.size.width * 0.7, height: 10)
                        .rotationEffect(.degrees(Double(index) * 18 - 48))
                }
                .offset(y: -proxy.size.height * 0.08)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .fill(AppColor.accentSecondary.opacity(0.48))
                            .frame(width: min(proxy.size.width, proxy.size.height) * 0.4)
                            .offset(y: -proxy.size.height * 0.16)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColor.textPrimary.opacity(0.08))
                            .frame(width: proxy.size.width * 0.74, height: proxy.size.height * 0.12)
                            .offset(y: proxy.size.height * 0.24)

                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.accent.opacity(0.98), AppColor.textPrimary, AppColor.textPrimary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: proxy.size.width * 0.46, height: proxy.size.height * 0.42)
                            .offset(y: proxy.size.height * 0.1)

                        Circle()
                            .fill(AppColor.textPrimary.opacity(0.98))
                            .frame(width: proxy.size.width * 0.24)
                            .offset(y: -proxy.size.height * 0.08)

                        Capsule(style: .continuous)
                            .fill(AppColor.textPrimary.opacity(0.92))
                            .frame(width: proxy.size.width * 0.26, height: proxy.size.height * 0.09)
                            .offset(y: proxy.size.height * 0.06)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack {
                    HStack {
                        Text("HERO")
                            .font(AppTypography.badge)
                            .foregroundStyle(AppColor.textTertiary)
                            .tracking(1.0)
                        Spacer()
                    }
                    .padding(12)

                    Spacer()

                    HStack {
                        Spacer()
                        Text("Character panel loading")
                            .font(AppTypography.badge)
                            .foregroundStyle(AppColor.textSecondary.opacity(0.82))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.surfaceElevated.opacity(0.88))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .allowsHitTesting(false)
    }
}

@MainActor
final class OptimizedComicImageViewModel: ObservableObject {
    @Published private(set) var image: UIImage?

    private let imagePipeline: ReaderImagePipeline
    private var loadTask: Task<Void, Never>?
    private var lastIdentity: String?

    init(imagePipeline: ReaderImagePipeline) {
        self.imagePipeline = imagePipeline
    }

    func load(
        thumbnailURL: URL?,
        fullImageURL: URL?,
        strategy: ComicImageLoadStrategy,
        displayScale: CGFloat,
        thumbnailMaxPixelSize: CGFloat,
        fullMaxPixelSize: CGFloat
    ) {
        let identity = [
            thumbnailURL?.absoluteString ?? "nil-thumb",
            fullImageURL?.absoluteString ?? "nil-full",
            "\(strategy)",
            "\(thumbnailMaxPixelSize)",
            "\(fullMaxPixelSize)",
            "\(displayScale)"
        ].joined(separator: "|")

        if identity == lastIdentity, image != nil {
            return
        }
        lastIdentity = identity

        loadTask?.cancel()
        image = nil

        let thumbnailTarget = max(64, thumbnailMaxPixelSize * displayScale)
        let fullTarget = max(64, fullMaxPixelSize * displayScale)
        let attempts = loadAttempts(
            strategy: strategy,
            thumbnailURL: thumbnailURL,
            fullImageURL: fullImageURL,
            thumbnailTarget: thumbnailTarget,
            fullTarget: fullTarget
        )

        loadTask = Task { [weak self] in
            guard let self else { return }
            for attempt in attempts {
                if Task.isCancelled { return }
                guard let image = await imagePipeline.image(
                    url: attempt.url,
                    targetPixelSize: attempt.targetPixelSize,
                    allowsNetwork: true
                ) else {
                    continue
                }
                if Task.isCancelled { return }
                await MainActor.run {
                    self.image = image
                }
                if attempt.isTerminalOnSuccess {
                    return
                }
            }
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
    }

    private func loadAttempts(
        strategy: ComicImageLoadStrategy,
        thumbnailURL: URL?,
        fullImageURL: URL?,
        thumbnailTarget: CGFloat,
        fullTarget: CGFloat
    ) -> [LoadAttempt] {
        switch strategy {
        case .thumbnailOnly:
            return [
                LoadAttempt.make(
                    url: thumbnailURL ?? fullImageURL,
                    targetPixelSize: thumbnailTarget,
                    isTerminalOnSuccess: true
                )
            ].compactMap { $0 }

        case .thumbnailThenFull:
            return [
                LoadAttempt.make(
                    url: thumbnailURL,
                    targetPixelSize: thumbnailTarget,
                    isTerminalOnSuccess: false
                ),
                LoadAttempt.make(
                    url: fullImageURL ?? thumbnailURL,
                    targetPixelSize: fullTarget,
                    isTerminalOnSuccess: true
                )
            ].compactMap { $0 }

        case .fullThenThumbnail:
            return [
                LoadAttempt.make(
                    url: fullImageURL,
                    targetPixelSize: fullTarget,
                    isTerminalOnSuccess: true
                ),
                LoadAttempt.make(
                    url: thumbnailURL ?? fullImageURL,
                    targetPixelSize: thumbnailTarget,
                    isTerminalOnSuccess: true
                )
            ].compactMap { $0 }
        }
    }
}

private struct LoadAttempt {
    let url: URL
    let targetPixelSize: CGFloat
    let isTerminalOnSuccess: Bool

    static func make(
        url: URL?,
        targetPixelSize: CGFloat,
        isTerminalOnSuccess: Bool
    ) -> LoadAttempt? {
        guard let url else { return nil }
        return LoadAttempt(
            url: url,
            targetPixelSize: targetPixelSize,
            isTerminalOnSuccess: isTerminalOnSuccess
        )
    }
}
