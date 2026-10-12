import Foundation

/// The formats Travaso can convert to.
enum OutputFormat: String, CaseIterable, Identifiable {
    case mp3, wav, flac, aiff, aac, alac, ogg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mp3:  "MP3"
        case .wav:  "WAV"
        case .flac: "FLAC"
        case .aiff: "AIFF"
        case .aac:  "AAC (.m4a)"
        case .alac: "Apple Lossless (.m4a)"
        case .ogg:  "OGG Vorbis"
        }
    }

    var fileExtension: String {
        switch self {
        case .mp3:  "mp3"
        case .wav:  "wav"
        case .flac: "flac"
        case .aiff: "aiff"
        case .aac, .alac: "m4a"
        case .ogg:  "ogg"
        }
    }

    /// Lossless formats store an exact bit depth (16 or 24-bit).
    var isLossless: Bool {
        switch self {
        case .wav, .flac, .aiff, .alac: true
        case .mp3, .aac, .ogg: false
        }
    }

    /// Highest sample rate the encoder accepts.
    var maxSampleRate: Int {
        switch self {
        case .mp3, .aac: 48_000
        default: 384_000
        }
    }
}
