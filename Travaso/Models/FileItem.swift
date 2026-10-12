import Foundation
import Observation

/// One row in the file list.
@MainActor @Observable
final class FileItem: Identifiable {
    enum Status: Equatable {
        case reading            // file facts not read yet
        case ready
        case converting(Double) // 0...1
        case done
        case skipped            // name conflict answered with "Skip"
        case failed(String)
    }

    let id = UUID()
    let url: URL
    let fileSize: Int64
    var info: AudioInfo?
    var outputURL: URL?         // where the converted file was saved
    var status: Status = .reading

    init(url: URL) {
        self.url = url
        self.fileSize = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    /// Ready rows, and failed rows that can be retried (their file facts were read).
    var canConvert: Bool {
        switch status {
        case .ready: true
        case .failed: info != nil
        default: false
        }
    }

    var isConverting: Bool {
        if case .converting = status { return true }
        return false
    }
}
