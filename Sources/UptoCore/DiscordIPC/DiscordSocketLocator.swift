import Foundation

// Discord opens its IPC socket at discord-ipc-N (N is 0 through 9)
// under the first temp directory it resolves. The lookup order below
// mirrors the one Discord uses. On macOS that lands in TMPDIR.
public struct DiscordSocketLocator: SocketLocator {
    // sun_path holds 104 bytes on macOS including the terminator.
    static let maxPathLength = 103

    private let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    public func candidatePaths() -> [String] {
        let envKeys = ["XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP"]
        var directories = envKeys.compactMap { environment[$0] }
        directories.append("/tmp")

        var seen = Set<String>()
        var paths: [String] = []
        for directory in directories {
            var clean = directory
            while clean.count > 1 && clean.hasSuffix("/") {
                clean.removeLast()
            }
            guard seen.insert(clean).inserted else { continue }
            for index in 0...9 {
                let path = "\(clean)/discord-ipc-\(index)"
                guard path.utf8.count <= Self.maxPathLength else { continue }
                paths.append(path)
            }
        }
        return paths
    }
}
