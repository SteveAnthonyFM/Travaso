import AppKit
import Observation
import UniformTypeIdentifiers

/// The file list: adding files and folders, removing them, and running a batch conversion.
@MainActor @Observable
final class ConversionQueue {
    var items: [FileItem] = []
    private(set) var isRunning = false
    var summary: String?

    /// How many files convert at the same time (the M1 has 4 performance cores).
    let maxParallel = 4

    private var runTask: Task<Void, Never>?

    nonisolated static let audioExtensions: Set<String> = [
        "mp3", "wav", "wave", "flac", "aif", "aiff", "aifc", "m4a", "m4b", "aac", "alac", "caf",
        "ogg", "oga", "opus", "wma", "ape", "wv", "mp2", "ac3", "mka", "dsf", "dff",
    ]

    // MARK: Adding and removing

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .folder]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.message = "Choose audio files or folders"
        guard panel.runModal() == .OK else { return }
        add(panel.urls)
    }

    /// Adds files; folders are scanned (including subfolders) for audio files.
    func add(_ urls: [URL]) {
        Task {
            let found = await Task.detached { Self.collectAudioFiles(in: urls) }.value
            let existing = Set(items.map { $0.url.standardizedFileURL.path })
            let newItems = found
                .filter { !existing.contains($0.standardizedFileURL.path) }
                .map { FileItem(url: $0) }
            guard !newItems.isEmpty else { return }
            items += newItems
            summary = nil
            await readInfo(for: newItems)
        }
    }

    func remove(_ ids: Set<FileItem.ID>) {
        items.removeAll { ids.contains($0.id) && !$0.isConverting }
    }

    func clear() {
        guard !isRunning else { return }
        items.removeAll()
        summary = nil
    }

    /// Called when format or quality changes: finished rows go back to Ready.
    func resetFinished() {
        guard !isRunning else { return }
        for item in items where item.status == .done || item.status == .skipped { item.status = .ready }
        summary = nil
    }

    nonisolated private static func collectAudioFiles(in urls: [URL]) -> [URL] {
        var result: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                let walker = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey],
                                           options: [.skipsHiddenFiles, .skipsPackageDescendants])
                var inFolder: [URL] = []
                while let file = walker?.nextObject() as? URL {
                    if isAudioFile(file) { inFolder.append(file) }
                }
                result += inFolder.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            } else if isAudioFile(url) {
                result.append(url)
            }
        }
        return result
    }

    nonisolated private static func isAudioFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if audioExtensions.contains(ext) { return true }
        return UTType(filenameExtension: ext)?.conforms(to: .audio) ?? false
    }

    /// Reads duration / channels / sample rate for new rows, a few at a time.
    private func readInfo(for newItems: [FileItem]) async {
        await withTaskGroup(of: Void.self) { group in
            var pending = newItems[...]
            func next() {
                guard let item = pending.popFirst() else { return }
                let url = item.url
                group.addTask {
                    let info = try? await FFmpeg.probe(url)
                    await MainActor.run {
                        item.info = info
                        item.status = info == nil ? .failed("Not a readable audio file") : .ready
                    }
                }
            }
            for _ in 0..<8 { next() }
            while await group.next() != nil { next() }
        }
    }

    // MARK: Converting

    /// One file ready to convert, after the pre-flight questions.
    private struct Job {
        let item: FileItem
        let output: URL
        let stereo: Bool
    }

    func start(settings: ConversionSettings) {
        guard !isRunning else { return }
        let toConvert = items.filter(\.canConvert)
        guard !toConvert.isEmpty else {
            summary = items.isEmpty ? nil : "Nothing new to convert"
            return
        }
        isRunning = true
        summary = nil
        runTask = Task {
            if let folder = settings.outputFolder, !Self.folderExists(folder) {
                await RunQuestions.showMessage("The output folder “\(folder.lastPathComponent)” can’t be found.",
                                               "It may have been moved, renamed or disconnected. Choose another folder in Settings (gear button).")
                isRunning = false
                runTask = nil
                return
            }
            let (jobs, skipped) = await askQuestions(for: toConvert, settings: settings)
            var converted = 0, failed = 0
            await withTaskGroup(of: Bool?.self) { group in
                var pending = jobs[...]
                func next() {
                    guard let job = pending.popFirst() else { return }
                    group.addTask { await self.convert(job, settings: settings) }
                }
                for _ in 0..<maxParallel { next() }
                while let result = await group.next() {
                    if result == true { converted += 1 } else if result == false { failed += 1 }
                    if !Task.isCancelled { next() }
                }
            }
            let stopped = Task.isCancelled
            var parts = ["\(converted) converted"]
            if skipped > 0 { parts.append("\(skipped) skipped") }
            if failed > 0 { parts.append("\(failed) failed") }
            summary = (stopped ? "Stopped — " : "") + parts.joined(separator: ", ")
            isRunning = false
            runTask = nil
        }
    }

    func stop() {
        runTask?.cancel()
    }

    /// Goes through the files in list order and asks the mono and name-conflict questions
    /// before anything converts. Returns the files to convert and how many were skipped.
    private func askQuestions(for toConvert: [FileItem], settings: ConversionSettings) async -> ([Job], Int) {
        let fm = FileManager.default
        var jobs: [Job] = []
        var skipped = 0
        var monoForAll: RunQuestions.MonoChoice?
        var conflictForAll: RunQuestions.ConflictChoice?
        var claimed = Set<String>()   // outputs already taken by earlier files in this run

        func key(_ url: URL) -> String { url.standardizedFileURL.path.lowercased() }
        func defaultOutput(_ item: FileItem) -> URL {
            ConversionPlan.outputURL(for: item.url, format: settings.format, folder: settings.outputFolder)
        }

        var monoLeft = toConvert.filter { $0.info?.channels == 1 }.count
        var conflictsLeft = toConvert.filter { fm.fileExists(atPath: defaultOutput($0).path) }.count

        for item in toConvert {
            if Task.isCancelled { break }

            var stereo = false
            if item.info?.channels == 1 {
                monoLeft -= 1
                if let choice = monoForAll {
                    stereo = choice == .stereo
                } else {
                    let answer = await RunQuestions.askMono(fileName: item.url.lastPathComponent, showApplyToAll: monoLeft > 0)
                    stereo = answer.choice == .stereo
                    if answer.applyToAll { monoForAll = answer.choice }
                }
            }

            var output = defaultOutput(item)
            let existsOnDisk = fm.fileExists(atPath: output.path)
            if existsOnDisk { conflictsLeft -= 1 }

            if claimed.contains(key(output)) {
                // Another file in this batch already uses this name: number it automatically.
                output = ConversionPlan.numberedURL(for: output, source: item.url) { claimed.contains(key($0)) }
            } else if existsOnDisk {
                let choice: RunQuestions.ConflictChoice
                if let all = conflictForAll {
                    choice = all
                } else {
                    let answer = await RunQuestions.askConflict(fileName: output.lastPathComponent,
                                                                folderName: output.deletingLastPathComponent().lastPathComponent,
                                                                showApplyToAll: conflictsLeft > 0)
                    choice = answer.choice
                    if answer.applyToAll { conflictForAll = answer.choice }
                }
                switch choice {
                case .overwrite: break
                case .skip:
                    item.status = .skipped
                    skipped += 1
                    continue
                case .keepBoth:
                    output = ConversionPlan.numberedURL(for: output, source: item.url) { claimed.contains(key($0)) }
                }
            }
            claimed.insert(key(output))
            jobs.append(Job(item: item, output: output, stereo: stereo))
        }
        return (jobs, skipped)
    }

    nonisolated private static func folderExists(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Converts one file. Returns true on success, false on failure, nil if stopped.
    private func convert(_ job: Job, settings: ConversionSettings) async -> Bool? {
        let item = job.item
        guard let info = item.info else { return false }
        // Write to a hidden temporary file first so a failed run never leaves a broken file behind.
        let temp = job.output.deletingLastPathComponent()
            .appendingPathComponent(".travaso-\(UUID().uuidString).\(settings.format.fileExtension)")
        let args = ConversionPlan.arguments(input: item.url, output: temp, info: info,
                                            settings: settings, stereo: job.stereo)

        item.status = .converting(0)
        do {
            try await FFmpeg.convert(arguments: args, duration: info.duration) { value in
                Task { @MainActor in
                    if item.isConverting { item.status = .converting(value) }
                }
            }
            try Task.checkCancellation()
            _ = try FileManager.default.replaceItemAt(job.output, withItemAt: temp)
            item.outputURL = job.output
            item.status = .done
            return true
        } catch {
            try? FileManager.default.removeItem(at: temp)
            if Task.isCancelled || error is CancellationError {
                item.status = .ready
                return nil
            }
            item.status = .failed(Self.friendlyMessage(for: error))
            return false
        }
    }

    func revealInFinder(_ ids: Set<FileItem.ID>) {
        let urls = items.filter { ids.contains($0.id) && $0.status == .done }.compactMap(\.outputURL)
        if !urls.isEmpty { NSWorkspace.shared.activateFileViewerSelecting(urls) }
    }

    private static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain,
           [NSFileWriteNoPermissionError, NSFileWriteVolumeReadOnlyError].contains(nsError.code) {
            return "Can't save in this folder (no permission)"
        }
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileWriteOutOfSpaceError {
            return "The disk is full"
        }
        if let ff = error as? FFmpegError {
            let msg = ff.message
            if msg.localizedCaseInsensitiveContains("Permission denied") { return "Can't save in this folder (no permission)" }
            if msg.localizedCaseInsensitiveContains("Invalid data") { return "The file seems damaged or isn't really audio" }
            return "Conversion failed: \(msg)"
        }
        return error.localizedDescription
    }
}
