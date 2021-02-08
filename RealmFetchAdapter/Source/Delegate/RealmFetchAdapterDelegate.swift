//
//  FetchControllerDelegate.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import RealmSwift


/// Set of fetch controller data change count
public typealias FetchControllerDataChange = (add: Int, update: Int, delete: Int)

// MARK: FetchControllerDelegate
public protocol RealmFetchAdapterDelegate: class {
    
    /// Notify the begining of fetch updates, retain your breath
    func onBeginFetchUpdate()
    
    /// Notify the success of fetching update, if you handle it that mean : enjoy the view
    func onFinishedFetchUpdate()
    
    /// Notify the success of initial fetching, if you handle it that mean : enjoy the view
    func onDidFinishInitialFetch()
    
    /**
     get ViewModel for single object at indexPath
     */
    func getViewModel(for object: RealmSwift.Object) -> FetchableObject?
    
    /**
     Fetch controller can keep old content if reload is not allowed, the next allowed reload after a block cause a reloadData instead of incremental
     
     - Note: return false to block live update
     
     */
    func canUpdateLiveData(changes: FetchControllerDataChange) -> Bool
    
    /**
     Notify delegate when new data is available but not staged
     
     - see: canUpdateLiveData
     
     */
    func newLiveDataIsAvailable()
    
}

