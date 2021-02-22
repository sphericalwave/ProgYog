//
//  AbsSkill+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//

import CoreData

extension AbsSkill {
    convenience init(jsonAbsSkill: JsonAbsSkill, moc: NSManagedObjectContext) {
        self.init(context:moc)
        self.name = jsonAbsSkill.name
        self.depth = Int16(jsonAbsSkill.depth)
        self.instructions = jsonAbsSkill.instructions
        self.symetrical = jsonAbsSkill.symmetrical  //TODO
        //self.timeCode = jsonAbsSkill.timeCode
        //TODO: missing skill family
    }
}

extension YogSeries {
    convenience init(name: String, url: URL, moc: NSManagedObjectContext) {
        self.init(context:moc)
        self.name = name
        self.url = url
    }
}

extension SkillFamily {
    convenience init(name: String, order: Int, absSkills: [AbsSkill], moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
        self.order = Int16(order)
        //TODO: Manual Codegen Required...Incoming
//        for skill in absSkills {
//            self.
//        }
    }
}
