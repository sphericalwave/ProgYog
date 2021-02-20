//
//  AbsSkill.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-20.
//

import Foundation

struct JsonAbsSkill: Codable {
    let depth: Int
    let instructions: String
    let name: String
    let symetrical: Bool
    let timeCode: Double?
}

struct JsonYogSeries: Codable {
    let name: String
    let url: URL
}

struct JsonSkillFamily: Codable {
    let name: String
    let order: Int
}


import CoreData

struct AbsSkillData
{
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        loadCoreData()
    }
    
    private func loadCoreData() {
        guard let array = loadJson(filename: "JsonAbsSkill") else { fatalError() }
        for item in array {
            //_ = AbsFd(absFdJson: item, moc: moc)
            _ = AbsSkill(jsonAbsSkill: item, moc: moc)
        }
    }
    
    private func loadJson(filename fileName: String) -> [JsonAbsSkill]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode([JsonAbsSkill].self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
}

extension AbsSkill {
    convenience init(jsonAbsSkill: JsonAbsSkill, moc: NSManagedObjectContext) {
        self.init(context:moc)
        self.name = jsonAbsSkill.name
        self.depth = Int16(jsonAbsSkill.depth)
        self.instructions = jsonAbsSkill.instructions
        self.symetrical = jsonAbsSkill.symetrical
        //self.timeCode = jsonAbsSkill.timeCode
        //TODO: missing skill family
    }
}
