//
//  FetchMonoTableViewController.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter
import RealmSwift


class FetchMonoTableViewController: FetchBaseTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration: RealmFetchAdapterConfiguration = RealmFetchAdapterConfiguration(
            entityType: DemoModel.self,
            predicate: NSPredicate(format: "id != ''"),
            sortDescriptors: [RealmSwift.SortDescriptor(keyPath: "sort", ascending: true)],
            sectionNameKeyPath: nil, // sort?
            forceViewModelMode: true,
            section: 0)
        self.fetchAdapter = TableViewRealmFetchAdapter(
            tableDelegate: self,
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
            
            let sectionObjects: [DemoModel] = self.createSectionData(number: 50, section: "WTF")
            
            //sectionObjects.append(contentsOf: self.createSectionData(number: 2, section: "2010"))
            //realm.addOrUpdateObjects(sectionObjects as NSFastEnumeration)
            realm.add(sectionObjects, update: Realm.UpdatePolicy.modified) // TODO: Check update policy
            try! realm.commitWrite()
        }
    }

}
