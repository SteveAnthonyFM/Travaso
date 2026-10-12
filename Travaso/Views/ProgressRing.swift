import SwiftUI

/// Round status indicator on each row: "Ready", a filling ring with %, ✓ or ✕.
struct ProgressRing: View {
    let status: FileItem.Status

    var body: some View {
        ZStack {
            Circle().stroke(Theme.ringTrack, lineWidth: Theme.ringLineWidth)

            switch status {
            case .reading:
                ProgressView().controlSize(.small)
            case .ready:
                Text("Ready").font(Theme.ringFont).foregroundStyle(Theme.textSecondary)
            case .converting(let value):
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(Theme.tint, style: StrokeStyle(lineWidth: Theme.ringLineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: value)
                Text("\(Int(value * 100))%").font(Theme.ringFont).foregroundStyle(Theme.textPrimary)
            case .done:
                Circle().stroke(Theme.success, lineWidth: Theme.ringLineWidth)
                Image(systemName: "checkmark").font(Theme.ringSymbolFont).foregroundStyle(Theme.success)
            case .skipped:
                Circle().stroke(Theme.skipped, lineWidth: Theme.ringLineWidth)
                Text("Skipped").font(Theme.ringFont).foregroundStyle(Theme.skipped)
            case .failed:
                Circle().stroke(Theme.failure, lineWidth: Theme.ringLineWidth)
                Image(systemName: "xmark").font(Theme.ringSymbolFont).foregroundStyle(Theme.failure)
            }
        }
        .frame(width: Theme.ringSize, height: Theme.ringSize)
    }
}
