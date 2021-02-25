//
//  JCJsonImporter.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-25.
//

import CoreData

struct __JSONImporter {
    let moc: NSManagedObjectContext
    
    private var series: [JsonYogSeries] = []
    // Families keyed by sereies names
    private var families: [String : [JsonSkillFamily]] = [:]
    // SKills keyed by family name
    private var skills: [String : [JsonSkillData]] = [:]
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        loadCoreData()
    }

    mutating func loadCoreData() {
        loadJSONData()
        
        var mos: [YogSeries] = []
        for series in self.series {
            let moSeries = YogSeries(json: series, moc: moc)
            let families = self.families[series.name]!
            for family in families {
                let moFamily = SkillFamily(json: family, moc: moc)
                let skills = self.skills[family.name]!
                let moSkills = Set(skills.map { AbsSkill(json: $0, moc: moc) })
                moFamily.addToAbsSkills(moSkills as NSSet)
                
//                for skill in skills {
//                    let moSkill = AbsSkill(json: skill, moc: moc)
//                    moSkill.skillFamily = moFamily
//                }
//                moFamily.yogSeries = moSeries
            }
            
            mos.append(moSeries)
        }
        
        guard moc.hasChanges else { return }
        try! moc.save()
    }
    
    mutating func loadJSONData() {
        self.series = loadJSON(fromFile: "YogSeries")
        let families: [JsonSkillFamily] = loadJSON(fromFile: "SkillFam")
        self.families = .init(grouping: families, by: \.series)
        
        let skills: [JsonSkillData] = loadJSON(fromFile: "ProgYogData")
        self.skills = .init(grouping: skills, by: \.skillFamily)
    }
    
    private func loadJSON<T: Decodable>(fromFile file: String) -> [T] {
        let url = Bundle.main.url(forResource: file, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let list = try? decoder.decode([T].self, from: data)
        return list ?? []
    }
}
