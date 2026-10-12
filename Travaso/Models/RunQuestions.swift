import AppKit

/// The questions Travaso asks before a batch starts, shown as sheets on the main window.
@MainActor
enum RunQuestions {
    enum MonoChoice { case keepMono, stereo }
    enum ConflictChoice { case overwrite, skip, keepBoth }

    static func askMono(fileName: String, showApplyToAll: Bool) async -> (choice: MonoChoice, applyToAll: Bool) {
        let alert = NSAlert()
        alert.messageText = "“\(fileName)” is mono."
        alert.informativeText = "It has a single channel. Keep it mono, or convert it to stereo (the same sound in both speakers)?"
        alert.addButton(withTitle: "Keep Mono")          // default (Return)
        alert.addButton(withTitle: "Convert to Stereo")
        let (response, all) = await present(alert, applyToAll: showApplyToAll)
        return (response == .alertSecondButtonReturn ? .stereo : .keepMono, all)
    }

    static func askConflict(fileName: String, folderName: String, showApplyToAll: Bool) async -> (choice: ConflictChoice, applyToAll: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "“\(fileName)” already exists in “\(folderName)”."
        alert.informativeText = "Overwrite it, skip this file, or keep both (the new file gets a number)?"
        alert.addButton(withTitle: "Overwrite")          // default (Return)
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Keep Both")
        let (response, all) = await present(alert, applyToAll: showApplyToAll)
        switch response {
        case .alertSecondButtonReturn: return (.skip, all)
        case .alertThirdButtonReturn:  return (.keepBoth, all)
        default:                       return (.overwrite, all)
        }
    }

    static func showMessage(_ title: String, _ detail: String) async {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = detail
        _ = await present(alert, applyToAll: false)
    }

    private static func present(_ alert: NSAlert, applyToAll: Bool) async -> (NSApplication.ModalResponse, Bool) {
        if applyToAll {
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = "Apply to all"
        }
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: \.isVisible) {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        return (response, alert.suppressionButton?.state == .on)
    }
}
