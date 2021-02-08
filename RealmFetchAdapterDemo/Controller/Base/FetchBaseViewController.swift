//
//  FetchBaseViewController.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter
import RealmSwift


class FetchBaseViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial object data
        self.createInitialData()
    }
    
    
    // MARK: Data management
    func clearAllData() {
        autoreleasepool {
            let realm = self.realm
            defer { realm.invalidate() }
            
            realm.beginWrite()
            realm.deleteAll()
            try! realm.commitWrite()
        }
    }
    func createInitialData() {
        // TO BE OVERRIDED
        self.clearAllData()
    }
    func createSectionData(number: Int, section: String) -> [DemoModel] {
        var result: [DemoModel] = []
        for index in 0..<number {
            result.append(self.createObject(sort: index, section: section))
        }
        return result
    }
    func createObject(sort: Int, section: String) -> DemoModel {
        let demoModel: DemoModel = DemoModel()
        demoModel.section = section
        demoModel.sort = sort
        demoModel.setColor(UIColor.random)
        return demoModel
    }
    
    
    // MARK: Common actions
    @IBAction func reloadData(id: Any) {
        // Override
    }
    @IBAction func rowShuffle(id: Any) {
        autoreleasepool {
            let realm = self.realm
            defer { realm.invalidate() }
            
            realm.beginWrite()
            
            let allObject = realm.objects(DemoModel.self).shuffled()
            guard let sectionSet: Set<String> = Set(allObject.map { $0.section}) as? Set<String> else { return }
            
            for sectionId in sectionSet {
                let sectionObjects = realm.objects(DemoModel.self).filter(NSPredicate(format: "section == %@", sectionId))
                let orderSet = sectionObjects.compactMap { $0.sort }.shuffled()
                
                for (index, object) in sectionObjects.enumerated() {
                    object.sort = orderSet[index]
                }
                
            }
            
            try! realm.commitWrite()
        }
    }

}


let _configuration: RealmSwift.Realm.Configuration = Realm.Configuration.defaultConfiguration


// MARK: RealmInstanceDelegate
extension FetchBaseViewController: RealmInstanceDelegate {
    
    var realm: RealmSwift.Realm {
        let realm = try! Realm(configuration: _configuration)
        
        return realm
    }
    
}
