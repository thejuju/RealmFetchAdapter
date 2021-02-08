//
//  FetchSectionCollectionViewController.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter
import RealmSwift


class FetchSectionCollectionViewController: FetchBaseCollectionViewController {

   
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let configuration: RealmFetchAdapterConfiguration = RealmFetchAdapterConfiguration(
            entityType: DemoModel.self,
            predicate: NSPredicate(format: "id != ''"),
            sortDescriptors: [RealmSwift.SortDescriptor(keyPath: "section", ascending: true),
                              RealmSwift.SortDescriptor(keyPath: "sort", ascending: true)],
            sectionNameKeyPath: "section", // sort?
            forceViewModelMode: true,
            section: 0)
        self.fetchAdapter = CollectionRealmFetchAdapter(
            collectionDelegate: self,
            realmDelegate: self,
            configuration: configuration,
            cacheName: nil,
            debugIdentifier: "DEMO")
    
        let _ = self.fetchAdapter?.performFetch()
    }
    
    override func createInitialData() {
        super.createInitialData()
        
        autoreleasepool {
            let realm = self.realm
            defer { realm.invalidate() }
            
            realm.beginWrite()
            
            var sectionObjects: [DemoModel] = self.createSectionData(number: 2, section: "2013")
            sectionObjects.append(contentsOf: self.createSectionData(number: 3, section: "2019"))
            sectionObjects.append(contentsOf: self.createSectionData(number: 4, section: "2018"))
            //sectionObjects.append(contentsOf: self.createSectionData(number: 2, section: "2010"))
            //realm.addOrUpdateObjects(sectionObjects as NSFastEnumeration)
            realm.add(sectionObjects, update: Realm.UpdatePolicy.modified) // TODO: Check update policy
            
            try! realm.commitWrite()
        }
    }

    func  stressTestData() {
        autoreleasepool {
            let realm = self.realm
            defer { realm.invalidate() }
            
            realm.beginWrite()
            
            let allObject = realm.objects(DemoModel.self).shuffled()
            guard let firstObjectSection: String = allObject.first?.section else { return }
            
            let sectionSet = Set(allObject.map { $0.section})
            
            let sectionObjects = realm.objects(DemoModel.self).filter(NSPredicate(format: "section == %@", firstObjectSection))
            var newSectionId: String = "\(Int.random(in: 1900...2000))"
            while sectionSet.contains(newSectionId) == true {
                newSectionId = "\(Int.random(in: 1900...2000))"
            }
            
            for object in sectionObjects {
                object.section = newSectionId
            }
            
            // Insert one new top section
            let sectionObjectsAdded: [DemoModel] = self.createSectionData(number: 10, section: "0")
            
            
            realm.add(sectionObjectsAdded, update: Realm.UpdatePolicy.modified) // TODO: Check update policy
            
            try! realm.commitWrite()
        }
        
    }

    
    // MARK: Tests
    @IBAction func sectionShuffle(id: Any) {
        autoreleasepool {
            let realm = self.realm
            defer { realm.invalidate() }
            
            realm.beginWrite()
            
            let allObject = realm.objects(DemoModel.self).shuffled()
            guard let firstObjectSection: String = allObject.first?.section else { return }
            
            let sectionSet = Set(allObject.map { $0.section})
            
            let sectionObjects = realm.objects(DemoModel.self).filter(NSPredicate(format: "section == %@", firstObjectSection))
            var newSectionId: String = "\(Int.random(in: 1900...2000))"
            while sectionSet.contains(newSectionId) == true {
                newSectionId = "\(Int.random(in: 1900...2000))"
            }
            
            for object in sectionObjects {
                object.section = newSectionId
            }
            
            try! realm.commitWrite()
        }
    }
    
    @IBAction func sectionStressTest(id: Any) {
        // Move old fist section to another position
        // Inset a new top section
        self.stressTestData()
        
        
    }
   
}


