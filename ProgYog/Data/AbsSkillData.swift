//
//  AbsSkillData.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-23.
//

import CoreData

struct AbsSkillData
{
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        loadCoreData()
    }
    
    private func loadCoreData() {
        guard let array = loadJson(filename: "ProgYogData") else { fatalError() }
        for item in array {
            _ = AbsSkill(jsonAbsSkill: item, moc: moc)
        }
    }
    
    private func loadJson(filename fileName: String) -> [JsonData]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode([JsonData].self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
    
    func loadYogSeries(jsonData: JsonData) {
        
    }
    
    func loadSkillFamilies(jsonData: JsonData) {
        guard let jsonData = loadJson(filename: "ProgYogData") else { fatalError() }
        for row in jsonData {
            //_ = AbsFd(absFdJson: item, moc: moc)
            _ = SkillFamily(row: row, moc: moc)//AbsSkill(jsonAbsSkill: row, moc: moc)
        }
    }
    
    func loadSkills(jsonData: JsonData) {
        guard let jsonData = loadJson(filename: "ProgYogData") else { fatalError() }
        for row in jsonData {
            //_ = AbsFd(absFdJson: item, moc: moc)
            _ = AbsSkill(jsonAbsSkill: row, moc: moc)
        }
    }
}
