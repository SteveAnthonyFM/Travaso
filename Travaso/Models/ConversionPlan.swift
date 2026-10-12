import Foundation

/// Pure conversion logic: from source facts + settings to output name, FFmpeg arguments and size estimate.
enum ConversionPlan {
    static let defaultSampleRate = 44_100

    static func sampleRate(for info: AudioInfo, _ settings: ConversionSettings) -> Int {
        let rate = settings.keepSampleRate && info.sampleRate > 0 ? info.sampleRate : defaultSampleRate
        return min(rate, settings.format.maxSampleRate)
    }

    /// 16 or 24. Only meaningful for lossless formats.
    static func bitDepth(for info: AudioInfo, _ settings: ConversionSettings) -> Int {
        settings.keepBitDepth && info.bitsPerSample > 16 ? 24 : 16
    }

    /// Surround is mixed down to stereo; mono and stereo are left as they are.
    static func channels(for info: AudioInfo) -> Int {
        min(max(info.channels, 1), 2)
    }

    /// Lossy bitrate in bits per second (MP3, AAC, OGG).
    static func bitRate(_ settings: ConversionSettings) -> Int {
        switch (settings.format, settings.quality) {
        case (.mp3, .high):   320_000
        case (.mp3, .medium): 192_000
        case (_, .high):      256_000
        case (_, .medium):    160_000
        }
    }

    /// Output file next to the source (or in `folder`), never the source file itself.
    static func outputURL(for source: URL, format: OutputFormat, folder: URL? = nil) -> URL {
        let dir = folder ?? source.deletingLastPathComponent()
        let stem = source.deletingPathExtension().lastPathComponent
        var url = dir.appendingPathComponent(stem).appendingPathExtension(format.fileExtension)
        if url.standardizedFileURL.path == source.standardizedFileURL.path {
            url = dir.appendingPathComponent("\(stem) 1").appendingPathExtension(format.fileExtension)
        }
        return url
    }

    /// "name 1.ext", "name 2.ext", … — the first that doesn't exist, isn't the source and isn't `taken`.
    static func numberedURL(for url: URL, source: URL, taken: (URL) -> Bool) -> URL {
        let dir = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var n = 1
        while true {
            let candidate = dir.appendingPathComponent("\(stem) \(n)").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: candidate.path),
               candidate.standardizedFileURL.path != source.standardizedFileURL.path,
               !taken(candidate) {
                return candidate
            }
            n += 1
        }
    }

    /// `stereo`: turn a mono source into stereo (the user's choice in the mono dialog).
    static func arguments(input: URL, output: URL, info: AudioInfo, settings: ConversionSettings,
                          stereo: Bool = false) -> [String] {
        let rate = sampleRate(for: info, settings)
        let bits = bitDepth(for: info, settings)
        let kbps = "\(bitRate(settings) / 1000)k"

        var args = ["-i", input.path,
                    "-map", "0:a:0", "-vn",        // audio only, no album art
                    "-map_metadata", "0"]          // carry over text tags

        // High-quality resampling; dither when lossless output is reduced to 16-bit.
        var filter = "aresample=filter_size=64"
        if settings.format.isLossless && bits == 16 && info.bitsPerSample > 16 {
            filter += ":dither_method=triangular"
        }
        args += ["-af", filter, "-ar", String(rate)]
        if info.channels > 2 || stereo { args += ["-ac", "2"] }

        switch settings.format {
        case .mp3:
            args += ["-c:a", "libmp3lame", "-b:a", kbps, "-id3v2_version", "3"]
        case .aac:
            args += ["-c:a", "aac_at", "-b:a", kbps]
        case .ogg:
            args += ["-c:a", "libvorbis", "-q:a", settings.quality == .high ? "8" : "5"]
        case .wav:
            args += ["-c:a", bits == 24 ? "pcm_s24le" : "pcm_s16le"]
        case .aiff:
            args += ["-c:a", bits == 24 ? "pcm_s24be" : "pcm_s16be", "-write_id3v2", "1"]
        case .flac:
            args += ["-c:a", "flac", "-sample_fmt", bits == 24 ? "s32" : "s16"]
            if bits == 24 { args += ["-bits_per_raw_sample", "24"] }
        case .alac:
            args += ["-c:a", "alac", "-sample_fmt", bits == 24 ? "s32p" : "s16p"]
            if bits == 24 { args += ["-bits_per_raw_sample", "24"] }
        }
        return args + ["-y", output.path]
    }

    /// Estimated output size in bytes; `approximate` is true when it's a rough guess.
    static func estimatedSize(info: AudioInfo, settings: ConversionSettings) -> (bytes: Int64, approximate: Bool) {
        let seconds = max(info.duration, 0)
        if !settings.format.isLossless {
            return (Int64(Double(bitRate(settings)) / 8 * seconds), true)
        }
        let pcm = Double(sampleRate(for: info, settings) * bitDepth(for: info, settings) / 8 * channels(for: info)) * seconds
        switch settings.format {
        case .flac, .alac: return (Int64(pcm * 0.55), true)
        default:           return (Int64(pcm), false)
        }
    }
}
