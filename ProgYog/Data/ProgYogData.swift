//
//  ProgYogData.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-20.
//

import UIKit
import CoreData

struct ProgYogData {  //TODO: Make a Struct?
    
    mutating func moc() -> NSManagedObjectContext { return persistentContainer.viewContext }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ProgYog")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    mutating func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    mutating func seedDB() {
        let usrDflt = UserDefaults.standard
        let key = "dbSeeded"
        let dbSeeded = usrDflt.bool(forKey: key)
        if !dbSeeded  {
            _ = AbsSkillData(moc: moc())  //FIXME: Style?
            //save()  //FIXME: Crashing on Save Because Required Relationship are Not in place
            usrDflt.set(true, forKey: key)
        }
        else { print("DB is Seeded.") }
    }
}