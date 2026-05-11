//
//  Persistence.swift
//  AudioWave
//
//  Created by Aaron Anthony on 2020-09-23.
//

import CoreData
import UIKit
import Combine

class CoreDataSrvc
{
    var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ProgYog")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? { fatalError("Unresolved error \(error), \(error.userInfo)") }
        })
        return container
    }()
    
    var moc: NSManagedObjectContext { return container.viewContext }

    func save() {
        guard moc.hasChanges else { return }
        do { try moc.save() } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    init() {
        NotificationCenter.default
            .addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { _ in
                if self.moc.hasChanges {
                    try? self.moc.save()
                }
            }
    }
    
    func launch() {
        let usrDflt = UserDefaults.standard
        let key = "notFirstLaunch"
        let notFirstLaunch = usrDflt.bool(forKey: key)
        if !notFirstLaunch  {
            
            
//            let alfred = Alfred(moc: moc)
//            _ = AbsFdData(moc: moc)
//            _ = AbsDshsData(moc: moc, alfred: alfred)
//            _ = AbsMealData(moc: moc, alfred: alfred)
//            _ = AbsMenuData(moc: moc, alfred: alfred)
//            //_ = CrtMenu(mealCount: 3, moc: moc)  //Crashes because absMeal == nil
//            //_ = trgt()
//            _ = AbsDish(fdCount: 3, moc: moc)
//            //loadWtr(moc: moc)
//            save()
//            usrDflt.set(true, forKey: key)
        }
        else {
            var lC = usrDflt.integer(forKey: "launchCount")
            lC += 1
            usrDflt.set(lC, forKey: "launchCount")
            print("launch \(lC)") }
            _ = ImportedJSON(moc: container.viewContext)
    }
    
//    func trgt() -> MacroTarget {
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MacroTarget")
//        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
//        fetchRequest.sortDescriptors = [sortDescriptor]
//        guard let trgts = try? moc.fetch(fetchRequest) as? [MacroTarget] else { fatalError() }
//
//        guard trgts.count != 0 else {
//            let t = MacroTarget(moc: moc, date: Date(), cal: 3300, prtn: 165, fat: 238, crb: 124, sgr: 60, fbr: 100, cost: 15)
//            return t
//        }
//        return trgts[0]
//    }
//
//    func absFd() -> AbsFd { //for NewCrtFdUi
//        let i = Img(uiImg: UIImage(systemName: "photo")!, moc: moc)
//        let m = Msrmt(nmbr: 100, unit: "g", ratio: 1, moc: moc)
//        let n = Nutrient(cal: 100, pro: 10, fat: 9, carb: 4, sug: 2, moc: moc)
//        let m2 = Msrmt(nmbr: 500, unit: "g", ratio: 1, moc: moc)
//        let p = Price(name: "superstore", price: 5.55, msrmt: m2, isRef: false, moc: moc)
//        return AbsFd(name: "Almonds", img: i, msrmt: m, nutrient: n, price: p, moc: moc)
//    }
//
//    func crtFd() -> CrtFd {
//        let m = Msrmt(nmbr: 100, unit: "g", ratio: 1, moc: moc)
//        let p = Price(name: "superstore", price: 5.55, msrmt: m, isRef: false, moc: moc)
//        return CrtFd(absFd: absFd(), scale: 1, date: Date(), confirmed: true, msrmt: m, price: p)
//    }
}

//  in memory coreData
//enum StorageType {
//    case persistent, inMemory
//}
//
//class CoreDataStore
//{
//    let persistentContainer: NSPersistentContainer
//
//    init(_ storageType: StorageType = .persistent) {
//        self.persistentContainer = NSPersistentContainer(name: "fu3l")
//
//        if storageType == .inMemory {
//            let description = NSPersistentStoreDescription()
//            description.url = URL(fileURLWithPath: "/dev/null")
//            self.persistentContainer.persistentStoreDescriptions = [description]
//        }
//
//        self.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//    }
