//
//  ErrorDetailView.swift
//  ProgYog
//

import SwiftUI
import UIKit

struct ErrorDetailView: View {
    let entry: ErrorLog.Entry

    var body: some View {
        List {
            Section {
                LabeledContent("Level", value: entry.level.label)
                LabeledContent("Source", value: entry.source)
                LabeledContent("When", value: entry.timestamp.formatted(date: .abbreviated, time: .standard))
            }
            Section("Message") {
                Text(entry.message)
                    .textSelection(.enabled)
            }
            if let detail = entry.detail, !detail.isEmpty {
                Section("Detail") {
                    Text(detail)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Event Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = exportText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var exportText: String {
        var parts: [String] = []
        parts.append("Level: \(entry.level.label)")
        parts.append("Source: \(entry.source)")
        parts.append("When: \(entry.timestamp.formatted(date: .abbreviated, time: .standard))")
        parts.append("Message: \(entry.message)")
        if let d = entry.detail, !d.isEmpty {
            parts.append("Detail:\n\(d)")
        }
        return parts.joined(separator: "\n")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ErrorDetailView(entry: .init(
            timestamp: Date(),
            level: .error,
            source: "CoreData.save",
            message: "Save failed: The operation couldn't be completed.",
            detail: """
            Domain: NSCocoaErrorDomain  Code: 134060
            Description: A Core Data error occurred.
            Reason: Mandatory attribute missing.
            """
        ))
    }
}
#endif
