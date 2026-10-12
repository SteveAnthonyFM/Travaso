import Foundation

enum Quality: String, CaseIterable, Identifiable {
    case high, medium
    var id: String { rawValue }
    var displayName: String { self == .high ? "High" : "Medium" }
}

/// Everything that decides how files are converted. Stored by the views with @AppStorage.
struct ConversionSettings: Equatable {
    var format: OutputFormat = .mp3
    var quality: Quality = .high
    var keepSampleRate = false
    var keepBitDepth = false
    /// nil = save next to the originals.
    var outputFolder: URL?
}
