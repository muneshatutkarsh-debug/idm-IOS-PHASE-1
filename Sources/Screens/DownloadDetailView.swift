import SwiftUI

struct DownloadDetailView: View {

    @Environment(\.tokens) private var tokens
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var downloads: DownloadManager

    let itemId: UUID

    @State private var share: PreviewFile?
    @State private var preview: PreviewFile?

    private var item: DownloadItem? { downloads.item(with: itemId) }

    var body: some View {
        ZStack {
            GradientBackground()

            if let item {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.sectionGap) {

                        header(item)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    IconTile(symbol: item.kind.symbolName, size: 46, filled: true)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.filename)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(tokens.ink)
                                            .lineLimit(2)
                                        Text(item.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(tokens.secondary)
                                    }

                                    Spacer(minLength: 0)

                                    if item.status == .completed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(tokens.accent)
                                    } else {
                                        Text(item.percentText)
                                            .font(.system(size: 16, weight: .bold).monospacedDigit())
                                            .foregroundColor(tokens.ink)
                                    }
                                }

                                GlassProgressBar(progress: item.progress)
                            }
                            .padding(.horizontal, Layout.rowHorizontal)
                            .padding(.vertical, 16)
                        }

                        VStack(alignment: .leading, spacing: Layout.headerGap) {
                            SectionHeader(title: "Details")
                            GlassCard {
                                detailRow("Status", item.status.title)
                                HairlineDivider()
                                detailRow("Downloaded", Formatters.bytes(item.bytesWritten))
                                HairlineDivider()
                                detailRow("Size", item.sizeText)
                                HairlineDivider()
                                detailRow("Speed", item.status == .downloading ? Formatters.speed(item.speed) : "\u{2014}")
                                HairlineDivider()
                                detailRow("Time left", item.status == .downloading ? Formatters.eta(item.secondsRemaining) : "\u{2014}")
                                HairlineDivider()
                                detailRow("Source", item.url.host ?? item.url.absoluteString)
                            }
                        }

                        actions(item)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.top, Layout.screenPadding)
                    .padding(.bottom, 40)
                }
            } else {
                EmptyStateView(
                    symbol: "tray.and.arrow.down.fill",
                    title: "Download unavailable",
                    message: "This item is no longer in your list."
                )
                .padding(Layout.screenPadding)
            }
        }
        .sheet(item: $share) { file in
            ShareSheet(items: [file.url])
        }
        .sheet(item: $preview) { file in
            QuickLookPreview(url: file.url).ignoresSafeArea()
        }
    }

    // MARK: - Pieces

    private func header(_ item: DownloadItem) -> some View {
        HStack {
            Text("Download")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(tokens.ink)

            Spacer()

            CircleGlassButton(symbol: "xmark") { dismiss() }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tokens.ink)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(tokens.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, Layout.rowHorizontal)
        .padding(.vertical, Layout.settingsRowVertical)
    }

    @ViewBuilder
    private func actions(_ item: DownloadItem) -> some View {
        VStack(spacing: 12) {
            if item.status == .completed {
                if let url = item.destinationURL {
                    PrimaryGradientButton(title: "Preview") {
                        preview = PreviewFile(url: url)
                    }
                    Button {
                        share = PreviewFile(url: url)
                    } label: {
                        secondaryLabel("Share", symbol: "square.and.arrow.up")
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            } else {
                PrimaryGradientButton(
                    title: item.status == .downloading || item.status == .queued ? "Pause" : "Resume"
                ) {
                    downloads.toggle(item)
                }

                Button {
                    downloads.cancel(item)
                } label: {
                    secondaryLabel("Cancel", symbol: "xmark.circle.fill")
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            Button {
                downloads.remove(item)
                dismiss()
            } label: {
                secondaryLabel("Remove from list", symbol: "trash", destructive: true)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private func secondaryLabel(_ title: String, symbol: String, destructive: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(destructive ? Tokens.arrowRed : tokens.accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassSurface(cornerRadius: 16, highlightHeight: 16)
    }
}
