import SwiftUI

struct FilesView: View {

    @Environment(\.tokens) private var tokens
    @EnvironmentObject private var library: FileLibrary

    @State private var search: String = ""
    @State private var preview: PreviewFile?
    @State private var share: PreviewFile?

    private var allFiles: [StoredFile] {
        library.files.isEmpty ? SampleData.files : library.files
    }

    private var filtered: [StoredFile] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return allFiles }
        return allFiles.filter { $0.name.lowercased().contains(query) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {

                ScreenTitle(text: "Files")

                GlassSearchField(placeholder: "Search files", text: $search)

                VStack(alignment: .leading, spacing: Layout.headerGap) {
                    SectionHeader(title: search.isEmpty ? "All Files" : "Results")

                    if filtered.isEmpty {
                        EmptyStateView(
                            symbol: "folder.fill",
                            title: "No files yet",
                            message: "Finished downloads show up here, ready to preview and share."
                        )
                    } else {
                        GlassCard {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, file in
                                FileRowView(file: file)
                                    .onTapGesture {
                                        guard !file.isSample else { return }
                                        preview = PreviewFile(url: file.url)
                                    }
                                    .contextMenu {
                                        Button {
                                            guard !file.isSample else { return }
                                            share = PreviewFile(url: file.url)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }

                                        Button(role: .destructive) {
                                            library.delete(file)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
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
        .onAppear { library.refresh() }
        .sheet(item: $preview) { item in
            QuickLookPreview(url: item.url).ignoresSafeArea()
        }
        .sheet(item: $share) { item in
            ShareSheet(items: [item.url])
        }
    }
}
