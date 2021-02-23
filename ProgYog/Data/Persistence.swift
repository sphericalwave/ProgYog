//
//  Persistence.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for n in 0..<10 {
            let newAbsSkill = AbsSkill(context: viewContext)
            newAbsSkill.name = "Skill #\(n)"
            newAbsSkill.depth = Int16(n)
            newAbsSkill.instructions = "instruction \(n)"
            newAbsSkill.symetrical = true
            newAbsSkill.timeCode = 75
            //TODO: missing skill family
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ProgYog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do { try context.save() }
            catch { print(error) }
        }
    }
    
    //TODO: reinstate function once db is stable
    mutating func seedDB() {
        loadAbsSkills()
        loadSkillFamilies()
        loadYogSeries()
    }
    
    func loadAbsSkills() {
        _ = AbsSkillData(moc: container.viewContext)  //FIXME: Style?
    }
    
    func loadSkillFamilies() {
        let fetchAbsSkills = NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
        let absSkills = try! container.viewContext.fetch(fetchAbsSkills) //FIXME: Force Unwrap

//        let skillFamilies = absSkills
//            .map { $0.family }
//            .reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
//
//        print(skillFamilies.count)

        //TODO: Deduplicate with Set Test Speeds
        let deduplicated = Set(absSkills.map(\.family))
        print(deduplicated.count)
        
//        for fam in deduplicated {
//            let fetchFamsAbsSkills = NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
//            //let predicateCourse = NSPredicate(format: "family == %@", fam)
//            fetchFamsAbsSkills.predicate = NSPredicate(format: "family == %@", fam)
//            let famSkills = try! container.viewContext.fetch(fetchFamsAbsSkills) //FIXME: Force Unwrap
//            print(famSkills)
//            _ = SkillFamily(name: fam, order: 1, absSkills: famSkills, moc: container.viewContext) //FIXME: FIX ORDER
//        }
    }
    
    func loadYogSeries() {
//        let series = ["A", "B", "C", "D", "E"]
//        let url = URL(string: "FIXME")!
//        for s in series {
//            let s = YogSeries(name: s, url: url, moc: container.viewContext)
//            s.addToSkillFamilies(<#T##value: SkillFamily##SkillFamily#>)
//            print("Setup Series \(s)")
//        }
    }
    
    mutating func firstLaunch() {
        let usrDflt = UserDefaults.standard
        let key = "dbSeeded"
        let dbSeeded = usrDflt.bool(forKey: key)
        if !dbSeeded  {
            seedDB()
            save()  //FIXME: Crashing on Save Because Required Relationship are Not in place
            usrDflt.set(true, forKey: key)
        }
        else { print("DB is Seeded.") }
    }
}
