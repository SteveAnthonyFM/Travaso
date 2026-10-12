import SwiftUI

/// Format dropdown, settings gear, status text and the green Convert button.
struct BottomBar: View {
    let queue: ConversionQueue
    @Binding var format: OutputFormat
    let onConvert: () -> Void
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 12) {
            Picker("Format", selection: $format) {
                ForEach(OutputFormat.allCases) { Text($0.displayName).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 190)
            .disabled(queue.isRunning)

            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape").font(Theme.toolbarIconFont)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.textSecondary)
            .help("Settings")
            .disabled(queue.isRunning)
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                SettingsPanel()
            }

            Text(statusText)
                .font(Theme.detailFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            Spacer()

            Button(action: queue.isRunning ? queue.stop : onConvert) {
                Text(queue.isRunning ? "Stop" : "Convert")
                    .font(Theme.buttonFont)
                    .foregroundStyle(queue.isRunning ? Theme.textPrimary : Theme.accentText)
                    .frame(minWidth: 74)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(queue.isRunning ? Theme.failure : Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!queue.isRunning && !hasWork)
            .opacity(!queue.isRunning && !hasWork ? 0.45 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(alignment: .top) { Rectangle().fill(Theme.divider).frame(height: 1) }
    }

    private var hasWork: Bool { queue.items.contains(where: \.canConvert) }

    private var statusText: String {
        if let summary = queue.summary { return summary }
        let count = queue.items.count
        if count == 0 { return "" }
        if queue.isRunning {
            let done = queue.items.filter { $0.status == .done }.count
            return "Converting… \(done) of \(count) done"
        }
        return count == 1 ? "1 file" : "\(count) files"
    }
}
