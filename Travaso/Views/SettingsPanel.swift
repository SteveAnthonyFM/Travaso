import SwiftUI

/// Quality and output options, shown from the gear button in the bottom bar.
struct SettingsPanel: View {
    @AppStorage("quality") private var quality: Quality = .high
    @AppStorage("keepSampleRate") private var keepSampleRate = false
    @AppStorage("keepBitDepth") private var keepBitDepth = false
    @AppStorage("useOutputFolder") private var useOutputFolder = false
    @AppStorage("outputFolderPath") private var outputFolderPath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings").font(Theme.titleFont).foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Picker("Quality", selection: $quality) {
                    ForEach(Quality.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                note(quality == .high
                     ? "MP3 320 kbps · AAC 256 kbps · OGG ≈256 kbps"
                     : "MP3 192 kbps · AAC 160 kbps · OGG ≈160 kbps")
            }

            divider

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Keep original sample rate", isOn: $keepSampleRate)
                note("Off: all files are saved at 44.1 kHz. (MP3 and AAC go up to 48 kHz.)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Keep original bit depth", isOn: $keepBitDepth)
                note("WAV, FLAC, AIFF, Apple Lossless. Off: 16-bit. On: 24-bit sources stay 24-bit.")
            }

            divider

            VStack(alignment: .leading, spacing: 8) {
                Text("Save converted files").foregroundStyle(Theme.textPrimary)
                Picker("Save converted files", selection: outputChoice) {
                    Text("Next to the originals").tag(false)
                    Text("In a folder:").tag(true)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                HStack(spacing: 8) {
                    Text(folderLabel)
                        .font(Theme.detailFont)
                        .foregroundStyle(useOutputFolder ? Theme.textPrimary : Theme.textTertiary)
                        .lineLimit(1).truncationMode(.middle)
                        .help(outputFolderPath)
                    Spacer()
                    Button("Choose…", action: chooseFolder)
                        .controlSize(.small)
                }
                .padding(.leading, 20)
            }

            note("Converting MP3, AAC or OGG to WAV or FLAC makes the file bigger, not better.")
                .padding(.top, 4)
        }
        .font(Theme.bodyFont)
        .tint(Theme.accent)   // Dark Teal for the segmented control, checkboxes and radio buttons
        .padding(18)
        .frame(width: 340)
    }

    /// Picking "In a folder" without a folder chosen yet opens the folder picker.
    private var outputChoice: Binding<Bool> {
        Binding {
            useOutputFolder
        } set: { wantsFolder in
            if wantsFolder && outputFolderPath.isEmpty {
                chooseFolder()
            } else {
                useOutputFolder = wantsFolder
            }
        }
    }

    private var folderLabel: String {
        outputFolderPath.isEmpty
            ? "No folder chosen"
            : (outputFolderPath as NSString).abbreviatingWithTildeInPath
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose where converted files are saved"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        outputFolderPath = url.path
        useOutputFolder = true
    }

    private var divider: some View {
        Rectangle().fill(Theme.divider).frame(height: 1)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Theme.detailFont)
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
