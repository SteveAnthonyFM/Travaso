import SwiftUI

/// One row: file name, output name, "original size › estimated size", progress ring.
struct FileRowView: View {
    let item: FileItem
    let settings: ConversionSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isLossless ? "waveform" : "music.note")
                .font(Theme.rowIconFont)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.url.lastPathComponent)
                    .font(Theme.rowTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).truncationMode(.middle)

                Text("→ " + outputName)
                    .font(Theme.detailFont)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1).truncationMode(.middle)

                if case .failed(let message) = item.status {
                    Text(message)
                        .font(Theme.detailFont)
                        .foregroundStyle(Theme.failureText)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }

            Spacer(minLength: 8)

            Text(sizeText)
                .font(Theme.monoDetailFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .fixedSize()

            ProgressRing(status: item.status)
        }
        .padding(.vertical, 6)
    }

    /// The output name; includes the folder when converted files go to a chosen folder.
    private var outputName: String {
        let url = item.outputURL ?? ConversionPlan.outputURL(for: item.url, format: settings.format,
                                                             folder: settings.outputFolder)
        guard settings.outputFolder != nil || item.outputURL != nil,
              url.deletingLastPathComponent() != item.url.deletingLastPathComponent() else {
            return url.lastPathComponent
        }
        return url.deletingLastPathComponent().lastPathComponent + "/" + url.lastPathComponent
    }

    private var isLossless: Bool {
        guard let codec = item.info?.codec else { return false }
        return codec.hasPrefix("pcm_") || ["flac", "alac", "wavpack", "ape", "tta"].contains(codec)
    }

    private var sizeText: String {
        let original = Self.format(item.fileSize)
        guard let info = item.info else { return original }
        let estimate = ConversionPlan.estimatedSize(info: info, settings: settings)
        return "\(original) › \(estimate.approximate ? "~" : "")\(Self.format(estimate.bytes))"
    }

    private static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
