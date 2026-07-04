//
//  UndoStackTests.swift
//  ProgYogTests
//

import XCTest
import SetLogKit
@testable import ProgYog

@MainActor
final class UndoStackTests: XCTestCase {

    func test_pushThenUndo_invokesRestore() {
        let stack = UndoStack()
        var restored = 0
        stack.push(description: "x") { restored += 1 }
        XCTAssertTrue(stack.canUndo)
        XCTAssertTrue(stack.undoLast())
        XCTAssertEqual(restored, 1)
        XCTAssertFalse(stack.canUndo)
    }

    func test_undoLast_LIFOOrder() {
        let stack = UndoStack()
        var order: [String] = []
        stack.push(description: "A") { order.append("A") }
        stack.push(description: "B") { order.append("B") }
        stack.push(description: "C") { order.append("C") }
        _ = stack.undoLast()
        _ = stack.undoLast()
        _ = stack.undoLast()
        XCTAssertEqual(order, ["C", "B", "A"])
    }

    func test_undoLast_emptyStack_returnsFalse() {
        let stack = UndoStack()
        XCTAssertFalse(stack.undoLast())
        XCTAssertFalse(stack.canUndo)
        XCTAssertNil(stack.lastRestoredDescription)
    }

    func test_undoLast_setsLastRestoredDescription() {
        let stack = UndoStack()
        stack.push(description: "1 set") { }
        _ = stack.undoLast()
        XCTAssertEqual(stack.lastRestoredDescription, "1 set")
    }

    func test_push_setsCanUndo_undoLastClearsWhenEmpty() {
        let stack = UndoStack()
        XCTAssertFalse(stack.canUndo)
        stack.push(description: "x") { }
        XCTAssertTrue(stack.canUndo)
        _ = stack.undoLast()
        XCTAssertFalse(stack.canUndo)
    }

    func test_maxDepth_dropsOldest() {
        let stack = UndoStack()
        var seen: [String] = []
        for i in 0..<30 {
            let id = "\(i)"
            stack.push(description: id) { seen.append(id) }
        }
        // 30 pushes, cap 25 → first 5 ("0".."4") dropped.
        // Pop all and verify newest "29" came first.
        while stack.undoLast() { }
        XCTAssertEqual(seen.count, 25)
        XCTAssertEqual(seen.first, "29")
        XCTAssertEqual(seen.last, "5")
    }

    func test_clear_emptiesStackAndCanUndoIsFalse() {
        let stack = UndoStack()
        stack.push(description: "x") { XCTFail("should not run") }
        stack.clear()
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.undoLast())
    }
}
