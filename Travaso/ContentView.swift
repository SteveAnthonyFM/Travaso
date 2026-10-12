import SwiftUI

/// The main window: file list on top, bottom bar below. Accepts dropped files and folders.
struct ContentView: View {
    let queue: ConversionQueue

    @AppStorage("format") private var format: OutputFormat = .mp3
    @AppStorage("quality") private var quality: Quality = .high
    @AppStorage("keepSampleRate") private var keepSampleRate = false
    @AppStorage("keepBitDepth") private var keepBitDepth = false
    @AppStorage("useOutputFolder") private var useOutputFolder = false
    @AppStorage("outputFolderPath") private var outputFolderPath = ""
    @State private var isDropTargeted = false

    private var settings: ConversionSettings {
        ConversionSettings(format: format, quality: quality,
                           keepSampleRate: keepSampleRate, keepBitDepth: keepBitDepth,
                           outputFolder: useOutputFolder && !outputFolderPath.isEmpty
                               ? URL(fileURLWithPath: outputFolderPath, isDirectory: true) : nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            FileListView(queue: queue, settings: settings, isDropTargeted: isDropTargeted)
            BottomBar(queue: queue, format: $format) {
                queue.start(settings: settings)
            }
        }
        .frame(minWidth: 620, minHeight: 360)
        .background(Theme.background)
        .tint(Theme.tint)
        .dropDestination(for: URL.self) { urls, _ in
            queue.add(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .onChange(of: settings) { queue.resetFinished() }
    }
}
