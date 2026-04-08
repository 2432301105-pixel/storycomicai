import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    let container: AppContainer

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            AppColor.inkBlack.ignoresSafeArea()
            HalftoneTextureView().ignoresSafeArea().allowsHitTesting(false)

            Group {
                switch viewModel.state {
                case .idle, .loading:
                    VStack(spacing: 20) {
                        Spacer()
                        InkSpinner()
                        Text("LOADING LIBRARY")
                            .font(AppTypography.badge)
                            .foregroundStyle(AppColor.textTertiary)
                            .tracking(2)
                        Spacer()
                    }

                case let .failed(message):
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(AppColor.comicRed)
                        Text("Load failed")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(message)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await viewModel.loadProjects() } }
                            .font(AppTypography.badge)
                            .foregroundStyle(AppColor.comicYellow)
                            .tracking(1.4)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(Capsule().strokeBorder(AppColor.comicYellow.opacity(0.5), lineWidth: 1.5))
                        Spacer()
                    }
                    .padding(.horizontal, 40)

                case let .loaded(projects):
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            libraryHeader(count: projects.count)
                            libraryGrid(projects: projects)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadProjects() }
    }

    private func libraryHeader(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppColor.comicBlue)
                    .frame(width: 20, height: 3)
                Text("LIBRARY")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.comicBlue)
                    .tracking(2.4)
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Your Comics")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AppColor.textOnLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColor.comicYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    @ViewBuilder
    private func libraryGrid(projects: [Project]) -> some View {
        if projects.isEmpty {
            // Empty state
            VStack(alignment: .leading, spacing: 14) {
                Text("Nothing here yet.")
                    .font(AppTypography.section)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Go to Home and create your first comic.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.inkPanel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(AppColor.panelBorder, lineWidth: 1.5)
            )
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(
                            viewModel: ProjectDetailViewModel(project: project),
                            container: container
                        )
                    } label: {
                        InkLibraryCard(project: project)
                    }
                    .buttonStyle(InkPressStyle())
                }
            }
        }
    }
}

// ─── Library card ─────────────────────────────────────────────────────────────

private struct InkLibraryCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover area
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColor.accent(for: project.style).opacity(0.7),
                                AppColor.inkPanel
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)

                // Halftone lines decoration
                VStack(spacing: 6) {
                    ForEach(0..<6) { _ in
                        Rectangle()
                            .fill(AppColor.paper.opacity(0.06))
                            .frame(height: 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // Style eyebrow
                Text(project.style.coverEyebrow.uppercased())
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.accent(for: project.style))
                    .tracking(1.4)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColor.inkBlack.opacity(0.7))
                    .padding(12)
            }
            .clipped()

            // Info strip
            VStack(alignment: .leading, spacing: 6) {
                Text(project.title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColor.accent(for: project.style))
                        .frame(width: 6, height: 6)
                    Text(project.statusDisplayName.uppercased())
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.accent(for: project.style))
                        .tracking(1)
                }
            }
            .padding(14)
            .background(AppColor.inkPanel)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(AppColor.panelBorderStrong, lineWidth: 1.5)
        )
    }
}

// ─── Ink spinner ──────────────────────────────────────────────────────────────

struct InkSpinner: View {
    @State private var angle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.panelBorder, lineWidth: 2)
                .frame(width: 36, height: 36)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(AppColor.comicYellow, lineWidth: 2)
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(angle))
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        LibraryView(
            viewModel: LibraryViewModel(projectService: AppContainer.preview().projectService),
            container: .preview()
        )
    }
    .previewContainer()
}
#endif
