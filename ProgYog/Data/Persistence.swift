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
            let newAbsSkill = CDAbsSkill(context: viewContext)
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
        __JSONImporter(moc: container.viewContext)
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
