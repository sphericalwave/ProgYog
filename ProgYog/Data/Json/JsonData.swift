//
//  AbsSkill.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-20.
//

import Foundation

struct JsonData: Codable {
    let series: String
    let url: URL
    let depth: Int
    let symmetrical: Bool  //TODO: Map to Bool?
    let skillFamily: String
    let name: String
    let instructions: String
    let timeCode: Double   //TODO: Make a Double
    let famOrder: Int
}




