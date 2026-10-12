import Foundation

/// Basic facts about a source audio file, read with ffprobe.
struct AudioInfo {
    var duration: Double        // seconds
    var channels: Int
    var sampleRate: Int
    var bitsPerSample: Int      // 0 when the codec has no fixed bit depth (e.g. MP3)
    var bitRate: Int            // bits per second, 0 if unknown
    var codec: String
}

struct FFmpegError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

/// Runs the copies of ffmpeg / ffprobe bundled inside Travaso.app.
enum FFmpeg {
    static var ffmpegURL: URL {
        Bundle.main.url(forAuxiliaryExecutable: "ffmpeg") ?? URL(fileURLWithPath: "/nonexistent/ffmpeg")
    }
    static var ffprobeURL: URL {
        Bundle.main.url(forAuxiliaryExecutable: "ffprobe") ?? URL(fileURLWithPath: "/nonexistent/ffprobe")
    }

    /// Reads duration, channel count, sample rate, etc. of the first audio stream.
    static func probe(_ file: URL) async throws -> AudioInfo {
        let args = ["-v", "error", "-select_streams", "a:0",
                    "-show_entries", "format=duration,bit_rate:stream=codec_name,channels,sample_rate,bits_per_raw_sample,bits_per_sample,bit_rate,duration",
                    "-of", "json", file.path]
        let result = try await run(ffprobeURL, args)
        guard result.status == 0,
              let json = try? JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any],
              let stream = (json["streams"] as? [[String: Any]])?.first else {
            throw FFmpegError(message: "Not a readable audio file.")
        }
        let format = json["format"] as? [String: Any] ?? [:]
        func num(_ v: Any?) -> Double { Double(v as? String ?? "") ?? (v as? Double) ?? Double(v as? Int ?? 0) }
        let rawBits = Int(num(stream["bits_per_raw_sample"]))
        return AudioInfo(
            duration: num(format["duration"]) > 0 ? num(format["duration"]) : num(stream["duration"]),
            channels: stream["channels"] as? Int ?? 2,
            sampleRate: Int(num(stream["sample_rate"])),
            bitsPerSample: rawBits > 0 ? rawBits : (stream["bits_per_sample"] as? Int ?? 0),
            bitRate: Int(num(stream["bit_rate"]) > 0 ? num(stream["bit_rate"]) : num(format["bit_rate"])),
            codec: stream["codec_name"] as? String ?? "")
    }

    /// Runs ffmpeg with the given arguments, reporting progress 0...1 based on the source duration.
    static func convert(arguments: [String], duration: Double, progress: @escaping @Sendable (Double) -> Void) async throws {
        let args = ["-hide_banner", "-nostdin", "-nostats", "-loglevel", "error", "-progress", "pipe:1"] + arguments
        let result = try await run(ffmpegURL, args) { line in
            // ffmpeg -progress prints lines like "out_time_us=1234567"
            guard duration > 0, line.hasPrefix("out_time_us="),
                  let us = Double(line.dropFirst("out_time_us=".count)) else { return }
            progress(min(max(us / 1_000_000 / duration, 0), 1))
        }
        guard result.status == 0 else {
            let lastLine = result.stderr.split(separator: "\n").last.map(String.init) ?? "Unknown error"
            throw FFmpegError(message: lastLine)
        }
        progress(1)
    }

    // MARK: - Process plumbing

    private struct RunResult { var status: Int32; var stdout: String; var stderr: String }

    /// Collects a process's output from background threads; the lock keeps access safe.
    private final class OutputBuffer: @unchecked Sendable {
        private let lock = NSLock()
        private var out = Data(), err = Data(), pending = ""

        /// Appends stdout data and returns any complete lines it finished.
        func appendOut(_ chunk: Data) -> [String] {
            lock.lock(); defer { lock.unlock() }
            out.append(chunk)
            pending += String(decoding: chunk, as: UTF8.self)
            var lines: [String] = []
            while let nl = pending.firstIndex(of: "\n") {
                lines.append(String(pending[..<nl]))
                pending = String(pending[pending.index(after: nl)...])
            }
            return lines
        }

        func appendErr(_ chunk: Data) {
            lock.lock(); err.append(chunk); lock.unlock()
        }

        func strings() -> (String, String) {
            lock.lock(); defer { lock.unlock() }
            return (String(decoding: out, as: UTF8.self), String(decoding: err, as: UTF8.self))
        }
    }

    private static func run(_ tool: URL, _ args: [String], onLine: ((String) -> Void)? = nil) async throws -> RunResult {
        guard FileManager.default.isExecutableFile(atPath: tool.path) else {
            throw FFmpegError(message: "The bundled \(tool.lastPathComponent) is missing from the app.")
        }
        try Task.checkCancellation()
        let process = Process()
        let handle = ProcessHandle(process)
        return try await withTaskCancellationHandler {
          try await withCheckedThrowingContinuation { continuation in
            process.executableURL = tool
            process.arguments = args
            let outPipe = Pipe(), errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            let buffer = OutputBuffer()
            outPipe.fileHandleForReading.readabilityHandler = { handle in
                buffer.appendOut(handle.availableData).forEach { onLine?($0) }
            }
            errPipe.fileHandleForReading.readabilityHandler = { handle in
                buffer.appendErr(handle.availableData)
            }
            process.terminationHandler = { p in
                outPipe.fileHandleForReading.readabilityHandler = nil
                errPipe.fileHandleForReading.readabilityHandler = nil
                buffer.appendOut(outPipe.fileHandleForReading.readDataToEndOfFile()).forEach { onLine?($0) }
                buffer.appendErr(errPipe.fileHandleForReading.readDataToEndOfFile())
                let (out, err) = buffer.strings()
                continuation.resume(returning: RunResult(status: p.terminationStatus, stdout: out, stderr: err))
            }
            do { try process.run() } catch { continuation.resume(throwing: error) }
          }
        } onCancel: {
            handle.terminate()
        }
    }

    /// Lets the Stop button end a running ffmpeg from another thread.
    private final class ProcessHandle: @unchecked Sendable {
        private let process: Process
        init(_ process: Process) { self.process = process }
        func terminate() { if process.isRunning { process.terminate() } }
    }
}
