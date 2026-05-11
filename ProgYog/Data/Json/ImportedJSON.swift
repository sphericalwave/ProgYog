//
//  JCJsonImporter.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-25.
//

import CoreData

//TODO: This works but it's not pretty
struct ImportedJSON {
    let moc: NSManagedObjectContext
    
    private var jsonSeries: [JsonYogSeries] = []
    // Families keyed by sereies names
    private var jsonFamilies: [String : [JsonSkillFamily]] = [:]
    // SKills keyed by family name
    private var jsonSkills: [String : [JsonSkillData]] = [:]
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        loadCoreData()
    }

    mutating func loadCoreData() {
        loadJSONData()
        
        for jsonSeries in self.jsonSeries {
            let cdSeries = CDYogSeries(json: jsonSeries, moc: moc)
            guard let families = self.jsonFamilies[jsonSeries.name] else { fatalError() }
            for jsonFamily in families {
                let cdFamily = CDSkillFamily(json: jsonFamily, moc: moc)
                cdFamily.yogSeries = cdSeries
                guard let jsonSkills = self.jsonSkills[jsonFamily.name] else { fatalError() }
                for jsonSkill in jsonSkills {
                    let cdSkill = CDAbsSkill(json: jsonSkill, moc: moc)
                    cdSkill.skillFamily = cdFamily
                }
            }
        }
        
        guard moc.hasChanges else { return }
        try! moc.save()
    }
    
    mutating func loadJSONData() {
        let s: [JsonYogSeries] = loadJSON(fromFile: "YogSeries")
        self.jsonSeries = s //.init(grouping: s, by: \.name) //loadJSON(fromFile: "YogSeries")
        
        let families: [JsonSkillFamily] = loadJSON(fromFile: "SkillFam")
        self.jsonFamilies = .init(grouping: families, by: \.series)
        
        let sks: [JsonSkillData] = loadJSON(fromFile: "ProgYogData")
        self.jsonSkills = .init(grouping: sks, by: \.skillFamily)  //TODO: QUestionable Neccessity
    }
    
    private func loadJSON<T: Decodable>(fromFile file: String) -> [T] {
        let url = Bundle.main.url(forResource: file, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let list = try? decoder.decode([T].self, from: data)
        return list ?? []
    }
}
