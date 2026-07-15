import Foundation

public enum LocalLogLevel: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
}

private struct LocalLogRecord: Codable, Sendable {
    let timestamp: Date
    let level: LocalLogLevel
    let event: String
    let metadata: [String: String]
}

public actor LocalEventLogger {
    private let directoryURL: URL
    private let maximumBytes: Int
    private let retainedFiles: Int
    private let encoder: JSONEncoder

    public init(directoryURL: URL, maximumBytes: Int = 512_000, retainedFiles: Int = 3) {
        self.directoryURL = directoryURL
        self.maximumBytes = max(128, maximumBytes)
        self.retainedFiles = max(1, retainedFiles)
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.sortedKeys]
    }

    public func record(
        level: LocalLogLevel,
        event: String,
        metadata: [String: String] = [:]
    ) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let record = LocalLogRecord(
            timestamp: Date(),
            level: level,
            event: event,
            metadata: redact(metadata)
        )
        var line = try encoder.encode(record)
        line.append(0x0A)
        let current = logURL(index: 0)
        let currentSize = ((try? FileManager.default.attributesOfItem(atPath: current.path)[.size]) as? NSNumber)?.intValue ?? 0
        if currentSize > 0 && currentSize + line.count > maximumBytes {
            try rotate()
        }
        if !FileManager.default.fileExists(atPath: current.path) {
            try line.write(to: current, options: .withoutOverwriting)
        } else {
            let handle = try FileHandle(forWritingTo: current)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        }
    }

    private func redact(_ metadata: [String: String]) -> [String: String] {
        let privateKeyParts = ["path", "salary", "name", "account", "token", "secret", "password", "email"]
        let windowsUserRoot = ["c:", "users"].joined(separator: "\\") + "\\"
        let unixUserRoot = "/" + "users" + "/"
        return metadata.mapValues { value in
            let normalized = value.lowercased()
            if normalized.contains(windowsUserRoot) || normalized.contains(unixUserRoot) || normalized.contains("%appdata%") {
                return "[REDACTED]"
            }
            return value
        }.mapValues { $0 }
        .merging(
            metadata.reduce(into: [String: String]()) { result, item in
                let key = item.key.lowercased()
                if privateKeyParts.contains(where: key.contains) {
                    result[item.key] = "[REDACTED]"
                }
            },
            uniquingKeysWith: { _, redacted in redacted }
        )
    }

    private func rotate() throws {
        if retainedFiles == 1 {
            try? FileManager.default.removeItem(at: logURL(index: 0))
            return
        }
        try? FileManager.default.removeItem(at: logURL(index: retainedFiles - 1))
        if retainedFiles > 2 {
            for index in stride(from: retainedFiles - 2, through: 1, by: -1) {
                let source = logURL(index: index)
                if FileManager.default.fileExists(atPath: source.path) {
                    try FileManager.default.moveItem(at: source, to: logURL(index: index + 1))
                }
            }
        }
        let current = logURL(index: 0)
        if FileManager.default.fileExists(atPath: current.path) {
            try FileManager.default.moveItem(at: current, to: logURL(index: 1))
        }
    }

    private func logURL(index: Int) -> URL {
        index == 0
            ? directoryURL.appending(path: "debug.log")
            : directoryURL.appending(path: "debug.\(index).log")
    }
}
