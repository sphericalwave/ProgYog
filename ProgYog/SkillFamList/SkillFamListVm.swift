//
//  SkillFamListVm.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import CoreData

class SkillFamListVm: NSObject, ObservableObject
{
    @Published var showModal = false
    @Published var pickerIndex = 0
    @Published var skillFamilies: [CDSkillFamily]
    let cdSrvc: CoreDataSrvc
    let moc: NSManagedObjectContext //{ cdSrvc.moc }
    
    private let fetchedResultsController: NSFetchedResultsController<CDSkillFamily>
    
    init(cdSrvc: CoreDataSrvc) {
        self.skillFamilies = []
        self.cdSrvc = cdSrvc
        self.moc = cdSrvc.moc
        let fetchRequest: NSFetchRequest<CDSkillFamily> = CDSkillFamily.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.returnsObjectsAsFaults = false
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: cdSrvc.moc,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        super.init()
        energizeFRC()
        //self.fetchedResultsController.delegate = self
    }
    
    private func energizeFRC() {
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        skillFamilies = fetchedResultsController.fetchedObjects ?? []
        print("absSkills.count = \(skillFamilies.count) - energizeFRC")
    }
}

extension SkillFamListVm: NSFetchedResultsControllerDelegate
{
    //can i have multiple frc's for fd, dsh, meal?
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //self.absFds = fetchedResultsController.fetchedObjects ?? []
        //print("absFds.count = \(absFds.count) - NSFetchedResultsControllerDelegate")
    }
}
