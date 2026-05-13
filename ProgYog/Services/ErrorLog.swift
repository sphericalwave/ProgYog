//
//  ErrorLog.swift
//  ProgYog
//
//  Central collector of recoverable errors and important events.
//  Surfaced in the Settings tab. No silent fails.
//

import Foundation

@MainActor
final class ErrorLog: ObservableObject {
    struct Entry: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let level: Level
        let source: String
        let message: String
        let detail: String?

        enum Level: String {
            case info, warning, error
            var label: String { rawValue.capitalized }
            var symbolName: String {
                switch self {
                case .info:    return "info.circle"
                case .warning: return "exclamationmark.triangle"
                case .error:   return "xmark.octagon.fill"
                }
            }
        }
    }

    @Published private(set) var entries: [Entry] = []
    @Published var unreadCount: Int = 0

    private let maxEntries = 200

    func record(
        _ level: Entry.Level,
        source: String,
        message: String,
        error: Error? = nil
    ) {
        let detail = error.map { describe($0) }
        let entry = Entry(
            timestamp: Date(),
            level: level,
            source: source,
            message: message,
            detail: detail
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries.removeLast(entries.count - maxEntries) }
        unreadCount += 1
        #if DEBUG
        let stamp = ISO8601DateFormatter().string(from: entry.timestamp)
        print("⚠️ [\(level.rawValue)][\(source)] \(message)\n  \(detail ?? "(no error)")\n  \(stamp)")
        #endif
    }

    func info(_ source: String, _ message: String) {
        record(.info, source: source, message: message)
    }

    func warning(_ source: String, _ message: String, error: Error? = nil) {
        record(.warning, source: source, message: message, error: error)
    }

    func error(_ source: String, _ message: String, error: Error? = nil) {
        record(.error, source: source, message: message, error: error)
    }

    func markRead() { unreadCount = 0 }

    func clear() {
        entries.removeAll()
        unreadCount = 0
    }

    var mostRecentError: Entry? {
        entries.first { $0.level == .error }
    }

    private func describe(_ error: Error) -> String {
        let nserror = error as NSError
        var lines: [String] = []
        lines.append("Domain: \(nserror.domain)  Code: \(nserror.code)")
        lines.append("Description: \(nserror.localizedDescription)")
        if let reason = nserror.localizedFailureReason {
            lines.append("Reason: \(reason)")
        }
        if let suggestion = nserror.localizedRecoverySuggestion {
            lines.append("Suggestion: \(suggestion)")
        }
        if !nserror.userInfo.isEmpty {
            lines.append("UserInfo:")
            for (k, v) in nserror.userInfo {
                lines.append("  \(k) = \(v)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
