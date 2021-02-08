//
//  RealmFetchAdapterConfiguration.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import RealmSwift


/// Configuration object for the FetchController
public class RealmFetchAdapterConfiguration: NSObject {
    
    /// Realm Entity type
    public let entityType: RealmSwift.Object.Type
    /// Main predicate
    public let predicate: NSPredicate
    /// Main sort descriptor
    public let sortDescriptors: [RealmSwift.SortDescriptor]
    /// Regroup array of result by key path value, use a view model for a section group by keypath
    public let sectionNameKeyPath: String?
    /// Is the attributed section of the fetcher on a section sensitive context, if is not set is 0 by default.
    public let section: Int
    /// force ViewModel pre-caching mode (automatic if using any keypath)
    public let forceViewModelMode:   Bool
    
    public init(entityType: RealmSwift.Object.Type,
                predicate: NSPredicate,
                sortDescriptors: [RealmSwift.SortDescriptor] = [],
                sectionNameKeyPath: String? = nil,
                forceViewModelMode: Bool = false,
                section: Int = 0) {
        
        self.entityType = entityType
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.sectionNameKeyPath = sectionNameKeyPath
        self.section = section
        self.forceViewModelMode = forceViewModelMode
        
        super.init()
    }
    
    /// is sectionned mode
    internal var isSectionned:      Bool {
        get {
            return self.sectionNameKeyPath != nil && self.sectionNameKeyPath != ""
        }
    }
    
}

