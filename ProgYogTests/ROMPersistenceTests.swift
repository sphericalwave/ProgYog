//
//  ROMPersistenceTests.swift
//  ProgYogTests
//
//  Regression test for the ROM-not-persisted bug: WorkoutSessionViewModel
//  .recordLog() set reps/rpt/rpe/rpd but never log.rom, so every logged set
//  stored rom = 0 and the SetLogSheet prefill (rom = Int(last.rom)) always
//  showed 0. Fixed by adding `log.rom = Int16(entry.rom)` in recordLog.
//

import XCTest
import SetLogKit
import CoreData
@testable import ProgYog

@MainActor
final class ROMPersistenceTests: XCTestCase {

    /// recordLog must persist the entered ROM so the next set's prefill
    /// (`rom = Int(lastLog.rom)`) reflects the real value, exactly like
    /// technique / exertion / discomfort.
    func testRecordLogPersistsROM() throws {
        // PreviewSupport seeds an in-memory store with workout "A"
        // (families + skills), so currentSkill resolves.
        let services = PreviewSupport.services
        let vm = WorkoutSessionViewModel(workoutCode: "A", services: services)

        let skill = try XCTUnwrap(
            vm.currentSkill,
            "Preview seed for workout A must yield a current skill"
        )

        let romValue = 73
        let entry = SetLogSheet.Entry(
            reps: 9,
            rom: romValue,
            rpt: 8,
            rpe: 6,
            rpd: 2,
            notes: "",
            decision: .repeat,
            isometric: false,
            sliceCount: 0
        )

        vm.recordLog(entry)

        // The session is brand-new, so its only set log is the one we just
        // recorded — assert ROM survived end-to-end.
        let saved = try XCTUnwrap(
            vm.session.orderedSetLogs.last,
            "recordLog should have created a SetLog on the session"
        )
        XCTAssertEqual(saved.absSkill, skill)
        XCTAssertEqual(
            Int(saved.rom), romValue,
            "ROM must be persisted by recordLog (regression: was always 0)"
        )

        // Prove it survives a real store round-trip (recordLog calls save()).
        services.coreData.moc.refreshAllObjects()
        let fr: NSFetchRequest<SetLog> = SetLog.fetchRequest()
        fr.predicate = NSPredicate(format: "SELF == %@", saved.objectID)
        let reloaded = try XCTUnwrap(services.coreData.moc.fetch(fr).first)
        XCTAssertEqual(
            Int(reloaded.rom), romValue,
            "ROM must be readable after a fresh fetch — this is what the "
            + "SetLogSheet prefill reads as Int(lastLog.rom)"
        )
        XCTAssertNotEqual(Int(reloaded.rom), 0)
    }
}
