import SwiftUI

@main
struct TravasoApp: App {
    @State private var queue = ConversionQueue()

    init() {
        // Dark mode only, including system dialogs and file pickers.
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
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
