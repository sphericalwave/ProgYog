//
//  JCJsonImporter2.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-25.
//

import CoreData

struct __JSONImporterTake2 {
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        self.moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        loadCoreData()
    }

    mutating func loadCoreData() {
        let skills: [JsonSkillData] = loadJSON(fromFile: "ProgYogData")
        let keyedByFamily = Dictionary(grouping: skills, by: \.skillFamily)
        let series = skills.map { JsonYogSeries(name: $0.series, url: $0.url) }
        let families = skills.map { JsonSkillFamily(name: $0.skillFamily, order: $0.famOrder, series: $0.series) }
        
//        var mos: [YogSeries] = []
//        for series in self.series {
//            let moSeries = YogSeries(json: series, moc: moc)
//            let families = self.families[series.name]!
//            for family in families {
//                let moFamily = SkillFamily(json: family, moc: moc)
//                let skills = self.skills[family.name]!
//                let moSkills = Set(skills.map { AbsSkill(json: $0, moc: moc) })
//                moFamily.addToAbsSkills(moSkills as NSSet)
                
//                for skill in skills {
//                    let moSkill = AbsSkill(json: skill, moc: moc)
//                    moSkill.skillFamily = moFamily
//                }
//                moFamily.yogSeries = moSeries
//            }
//
//            mos.append(moSeries)
//        }
        
        guard moc.hasChanges else { return }
        try! moc.save()
    }
    
    private func loadJSON<T: Decodable>(fromFile file: String) -> [T] {
        let url = Bundle.main.url(forResource: file, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let list = try? decoder.decode([T].self, from: data)
        return list ?? []
    }
}
