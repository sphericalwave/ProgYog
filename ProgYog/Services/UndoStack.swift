//
//  UndoStack.swift
//  ProgYog
//
//  Manual snapshot/restore stack — NOT NSUndoManager. Scope is intentionally
//  "deletions only" so editing fields, stepper changes, and notes typing
//  are never affected. Each entry holds a description + restore closure;
//  call sites push BEFORE `moc.delete(...)` and capture the pre-delete
//  snapshot in the closure.
//

import Foundation
import Combine

@MainActor
final class UndoStack: ObservableObject {

    struct Entry {
        let description: String
        let restore: () -> Void
    }

    @Published private(set) var canUndo: Bool = false
    /// Drives the toast. Set when an undo completes; the toast view clears
    /// it back to nil after a brief delay.
    @Published var lastRestoredDescription: String?

    private var stack: [Entry] = []
    private let maxDepth = 25

    func push(description: String, restore: @escaping () -> Void) {
        stack.append(Entry(description: description, restore: restore))
        if stack.count > maxDepth {
            stack.removeFirst(stack.count - maxDepth)
        }
        canUndo = !stack.isEmpty
    }

    @discardableResult
    func undoLast() -> Bool {
        guard let entry = stack.popLast() else { return false }
        canUndo = !stack.isEmpty
        entry.restore()
        lastRestoredDescription = entry.description
        return true
    }

    func clear() {
        stack.removeAll()
        canUndo = false
    }
}
