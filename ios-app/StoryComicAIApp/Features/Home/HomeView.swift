import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let container: AppContainer
    @State private var navigateToCreateProject = false
    @State private var heroAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.inkBlack.ignoresSafeArea()

            // Halftone dot texture overlay
            HalftoneTextureView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                        .padding(.bottom, 40)

                    recentSection
                        .padding(.bottom, 120) // space for tab bar
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCreateProject) {
            CreateProjectView(
                viewModel: CreateProjectViewModel(),
                flowStore: CreateProjectFlowStore(),
                container: container
            )
        }
        .task { await viewModel.loadRecentProjects() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { heroAppeared = true }
        }
    }

    // ─── Hero ─────────────────────────────────────────────────────────────────
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Brand eyebrow
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppColor.comicRed)
                    .frame(width: 20, height: 3)
                Text("STORY COMIC AI")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.comicRed)
                    .tracking(2.4)
            }
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 12)
            .animation(.easeOut(duration: 0.5).delay(0.05), value: heroAppeared)

            // Big title
            VStack(alignment: .leading, spacing: 4) {
                Text("Your story,")
                    .font(.system(size: 46, weight: .black, design: .serif))
                    .foregroundStyle(AppColor.textPrimary)
                Text("your comic.")
                    .font(.system(size: 46, weight: .black, design: .serif))
                    .foregroundStyle(AppColor.comicYellow)
            }
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 16)
            .animation(.easeOut(duration: 0.5).delay(0.15), value: heroAppeared)

            // Create CTA panel
            createPanel
                .opacity(heroAppeared ? 1 : 0)
                .offset(y: heroAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.25), value: heroAppeared)
        }
    }

    private var createPanel: some View {
        Button {
            navigateToCreateProject = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                // Panel background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColor.comicYellow)

                // Ink border (comic panel effect)
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(AppColor.textOnLight.opacity(0.8), lineWidth: 2.5)

                // Content
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Panel number (comic style)
                        Text("01")
                            .font(.system(size: 11, weight: .black, design: .default))
                            .foregroundStyle(AppColor.textOnLight.opacity(0.35))
                            .tracking(1)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Create New Comic")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundStyle(AppColor.textOnLight)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                            Text("Turn any story into a stunning graphic novel in minutes.")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textOnLight.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 6) {
                            Text("START CREATING")
                                .font(AppTypography.badge)
                                .foregroundStyle(AppColor.comicYellow)
                                .tracking(1.4)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppColor.comicYellow)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColor.inkBlack)
                        .clipShape(Capsule())
                    }
                    .padding(24)

                    // Decorative comic panel stack (right-aligned, doesn't crowd text)
                    VStack(spacing: -6) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColor.textOnLight.opacity(0.08 + Double(i) * 0.04))
                                .frame(width: 44, height: 56)
                                .rotationEffect(.degrees(Double(i - 1) * 5))
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .layoutPriority(-1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .shadow(color: AppColor.comicYellow.opacity(0.3), radius: 24, x: 0, y: 8)
        }
        .buttonStyle(InkPressStyle())
    }

    // ─── Recent projects ──────────────────────────────────────────────────────
    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(alignment: .firstTextBaseline) {
                Text("RECENT WORK")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(2.0)
                Spacer()
                Rectangle()
                    .fill(AppColor.panelBorder)
                    .frame(height: 1)
                    .frame(maxWidth: 80)
            }

            switch viewModel.recentProjectsState {
            case .idle, .loading:
                InkLoadingView()
                    .frame(height: 200)

            case let .failed(message):
                InkErrorView(message: message) {
                    Task { await viewModel.loadRecentProjects() }
                }

            case let .loaded(projects):
                if projects.isEmpty {
                    emptyState
                } else {
                    recentList(projects: Array(projects.prefix(5)))
                }
            }
        }
    }

    private func recentList(projects: [Project]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                NavigationLink {
                    ProjectDetailView(
                        viewModel: ProjectDetailViewModel(project: project),
                        container: container
                    )
                } label: {
                    InkProjectRow(project: project, index: index + 1)
                }
                .buttonStyle(InkPressStyle())

                if project.id != projects.last?.id {
                    Rectangle()
                        .fill(AppColor.panelBorder)
                        .frame(height: 1)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(AppColor.panelBorderStrong, lineWidth: 1.5)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No comics yet.")
                .font(AppTypography.section)
                .foregroundStyle(AppColor.textPrimary)
            Text("Create your first comic above — it takes under 60 seconds.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.inkPanel)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(AppColor.panelBorder, lineWidth: 1.5)
        )
    }
}

// ─── Sub-views ────────────────────────────────────────────────────────────────

private struct InkProjectRow: View {
    let project: Project
    let index: Int

    var body: some View {
        HStack(spacing: 16) {
            // Index number
            Text(String(format: "%02d", index))
                .font(.system(size: 12, weight: .black, design: .default))
                .foregroundStyle(AppColor.textTertiary)
                .frame(width: 28)

            // Mini cover strip
            Rectangle()
                .fill(AppColor.accent(for: project.style))
                .frame(width: 3, height: 44)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(project.statusDisplayName.uppercased())
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.accent(for: project.style))
                    .tracking(1.2)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColor.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// ─── Halftone texture ─────────────────────────────────────────────────────────

struct HalftoneTextureView: View {
    var body: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 18
            let dotRadius: CGFloat = 1.2
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let path = Path(ellipseIn: CGRect(
                        x: x - dotRadius, y: y - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    ))
                    context.fill(path, with: .color(AppColor.paper.opacity(0.04)))
                    x += dotSpacing
                }
                y += dotSpacing
            }
        }
    }
}

// ─── Ink press button style ───────────────────────────────────────────────────

struct InkPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// ─── Ink loading / error ──────────────────────────────────────────────────────

private struct InkLoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColor.comicYellow.opacity(pulse ? 0.8 : 0.2))
                        .frame(width: 32, height: 32)
                        .animation(.easeInOut(duration: 0.7).delay(Double(i) * 0.15).repeatForever(), value: pulse)
                }
            }
            Text("LOADING COMICS...")
                .font(AppTypography.badge)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .onAppear { pulse = true }
    }
}

private struct InkErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Failed to load")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColor.comicRed)
            Text(message)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
            Button("Retry", action: retry)
                .font(AppTypography.badge)
                .foregroundStyle(AppColor.comicYellow)
                .tracking(1.2)
        }
        .padding(20)
        .background(AppColor.inkPanel)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(AppColor.comicRed.opacity(0.4), lineWidth: 1.5))
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(projectService: AppContainer.preview().projectService),
            container: .preview()
        )
    }
    .previewContainer()
}
#endif
