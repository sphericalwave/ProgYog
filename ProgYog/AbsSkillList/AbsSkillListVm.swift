//
//  AbsSkillListVm.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import CoreData

class AbsSkillListVm: NSObject, ObservableObject
{
    @Published var showModal = false
    @Published var pickerIndex = 0
    @Published var absSkills: [CDAbsSkill]
    let cdSrvc: CoreDataSrvc
    let moc: NSManagedObjectContext //{ cdSrvc.moc }
    
    private let fetchedResultsController: NSFetchedResultsController<CDAbsSkill>
    
    init(cdSrvc: CoreDataSrvc) {
        self.absSkills = []
        self.cdSrvc = cdSrvc
        self.moc = cdSrvc.moc
        let fetchRequest: NSFetchRequest<CDAbsSkill> = CDAbsSkill.fetchRequest()
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
        absSkills = fetchedResultsController.fetchedObjects ?? []
        print("absSkills.count = \(absSkills.count) - energizeFRC")
    }
}

extension AbsSkillListVm: NSFetchedResultsControllerDelegate
{
    //can i have multiple frc's for fd, dsh, meal?
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //self.absFds = fetchedResultsController.fetchedObjects ?? []
        //print("absFds.count = \(absFds.count) - NSFetchedResultsControllerDelegate")
    }
}
