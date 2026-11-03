import SwiftUI

@main
struct TravasoApp: App {
    @State private var queue = ConversionQueue()

    init() {
        // Dark mode only, including system dialogs and file pickers.
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        // Quitting mid-batch stops ffmpeg and removes its half-written temporary files.
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: nil) { _ in
            ActiveWork.shared.terminateAll()
        }
    }

    var body: some Scene {
        Window("Travaso", id: "main") {
            ContentView(queue: queue)
                .preferredColorScheme(.dark)
                .containerBackground(Theme.background, for: .window)   // title bar blends in
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Files…") { queue.showOpenPanel() }
                    .keyboardShortcut("o")
            }
        }
    }
}
