import SwiftUI

struct DownloadsView: View {

    @Environment(\.tokens) private var tokens
    @EnvironmentObject private var downloads: DownloadManager

    @Binding var showAddSheet: Bool
    @Binding var focusedDownload: DownloadItem?

    @State private var search: String = ""

    private var filtered: [DownloadItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return downloads.items }
        return downloads.items.filter { $0.filename.lowercased().contains(query) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {

                header

                GlassSearchField(placeholder: "Search downloads", text: $search)

                VStack(alignment: .leading, spacing: Layout.headerGap) {
                    SectionHeader(title: search.isEmpty ? "Active & Recent" : "Results")

                    if filtered.isEmpty {
                        if downloads.items.isEmpty {
                            EmptyStateView(
                                symbol: "tray.and.arrow.down.fill",
                                title: "Ready for your first download",
                                message: "Paste a link or share one from another app to get started.",
                                actionTitle: "Add Download",
                                action: { showAddSheet = true }
                            )
                        } else {
                            EmptyStateView(
                                symbol: "magnifyingglass",
                                title: "No matches",
                                message: "Nothing here matches \u{201C}\(search)\u{201D}."
                            )
                        }
                    } else {
                        GlassCard {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                                DownloadRowView(item: item)
                                    .onTapGesture { focusedDownload = item }
                                    .contextMenu {
                                        if item.status == .downloading || item.status == .queued {
                                            Button {
                                                downloads.pause(item)
                                            } label: {
                                                Label("Pause", systemImage: "pause.fill")
                                            }
                                        } else if item.status == .paused || item.status == .failed {
                                            Button {
                                                downloads.resume(item)
                                            } label: {
                                                Label("Resume", systemImage: "play.fill")
                                            }
                                        }

                                        Button {
                                            focusedDownload = item
                                        } label: {
                                            Label("Details", systemImage: "info.circle")
                                        }

                                        Button(role: .destructive) {
                                            downloads.remove(item)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }

                                if index < filtered.count - 1 {
                                    HairlineDivider()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Layout.screenPadding)
            .padding(.bottom, Layout.bottomInset)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ScreenTitle(text: "Downloads")

            Spacer()

            HStack(spacing: 10) {
                CircleGlassButton(symbol: "plus") { showAddSheet = true }

                Menu {
                    Button {
                        downloads.pauseAll()
                    } label: {
                        Label("Pause All", systemImage: "pause.fill")
                    }
                    Button {
                        downloads.resumeAll()
                    } label: {
                        Label("Resume All", systemImage: "play.fill")
                    }
                    Button(role: .destructive) {
                        downloads.clearCompleted()
                    } label: {
                        Label("Clear Completed", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tokens.accent)
                        .frame(width: 38, height: 38)
                        .glassSurface(cornerRadius: 19, highlightHeight: 14)
                }
            }
        }
    }
}
