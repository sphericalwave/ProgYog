//
//  AbsSkillData.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-23.
//

import CoreData

struct ProgYogData
{
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        loadCoreData()
    }
    
    private func loadCoreData() {
        guard let array = loadJson(filename: "ProgYogData") else { fatalError() }
        loadSkills(jsonData: array)
        loadSkillFamilies(jsonData: array)
        loadYogSeries(jsonData: array)
        
        //TODO: save
    }
    
    private func loadJson(filename fileName: String) -> [JsonSkillData]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode([JsonSkillData].self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
    
    func loadYogSeries(jsonData: [JsonSkillData]) {
        let deduplicated = Set(jsonData.map(\.series))
        print("Series count: \(deduplicated.count)")
    }
    
    func loadSkillFamilies(jsonData: [JsonSkillData]) {
        if let url = Bundle.main.url(forResource: "SkillFam", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let skillFams = try decoder.decode([JsonSkillFamily].self, from: data)
                for skillFam in skillFams {
                    _ = SkillFamily(json: skillFam, moc: moc)
                }
            } catch { print("error:\(error)") }
        }
        
//        let test = jsonData.filter(<#T##isIncluded: (JsonData) throws -> Bool##(JsonData) throws -> Bool#>)
//
//        let deduplicated = Set(jsonData.map(\.skillFamily))
//        //print("SkillFam count: \(deduplicated.count)")
//
//        for fam in deduplicated {
//            let f = SkillFamily(row: fam, moc: moc)
//            let skillRequest = NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
//            skillRequest.predicate = NSPredicate(format: "family == %@", fam)
//            let famSkills = try! moc.fetch(skillRequest)
//            f.
//        }
        
        
    }
    
    func loadSkills(jsonData: [JsonSkillData]) {
        for row in jsonData {
            _ = AbsSkill(json: row, moc: moc)
        }
    }
}
