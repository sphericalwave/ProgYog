//
//  ProgressionEvaluator.swift
//  ProgYog
//
//  Intuitive Training Protocol — suggests progress / hold / regress
//  from the last 3 logged sets for a given skill.
//
//  Rule (from manual):
//    Sustained RPT ≥ 8, RPD ≤ 3, RPE ≥ 6 across 3 sessions → progress.
//    High RPD or low RPT → regress. Otherwise hold.
//

import Foundation

enum ProgressionDecision: String, CaseIterable {
    case progress, hold, regress
}

struct RatedSet: Equatable {
    let rpt: Int        // technique 1–10
    let rpe: Int        // exertion 1–10
    let rpd: Int        // discomfort 1–10
    let loggedAt: Date
}

struct ProgressionEvaluator {
    static let progressWindow = 3
    static let rptMin = 8
    static let rpdMax = 3
    static let rpeMin = 6
    static let regressRpdMin = 7
    static let regressRptMax = 4

    func suggest(from recent: [RatedSet]) -> ProgressionDecision {
        let last3 = Array(recent.suffix(Self.progressWindow))
        guard last3.count == Self.progressWindow else { return .hold }

        let meets = last3.allSatisfy {
            $0.rpt >= Self.rptMin && $0.rpd <= Self.rpdMax && $0.rpe >= Self.rpeMin
        }
        if meets { return .progress }

        let regressSignal = last3.contains {
            $0.rpd >= Self.regressRpdMin || $0.rpt <= Self.regressRptMax
        }
        if regressSignal { return .regress }

        return .hold
    }
}
