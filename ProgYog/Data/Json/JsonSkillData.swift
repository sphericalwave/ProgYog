//
//  AbsSkill.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-20.
//

import Foundation

struct JsonSkillData: Codable {
    let series: String  //TODO: REmove
    let url: URL        //TODO: REmove
    let depth: Int
    let symmetrical: Bool
    let skillFamily: String
    let name: String
    let instructions: String
    let timeCode: Double
    let famOrder: Int   //TODO: REmove
}

extension JsonSkillData: Equatable { }



