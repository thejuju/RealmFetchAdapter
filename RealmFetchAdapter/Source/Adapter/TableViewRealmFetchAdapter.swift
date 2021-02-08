//
//  TableViewRealmFetchAdapter.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import UIKit
import DifferenceKit


/// Table view fetch controller delegate
public protocol TableViewRealmFetchAdapterDelegate: RealmFetchAdapterDelegate {
    /// CollectionView to update
    func getTableView() -> UITableView?
    
}


/**
 Use this controller to automaticaly listen realm fetch request modifications for UITableView
 
 - Important : this fetch controller helper is very disapointed when you manipulate reloadData behind it... à vos risque et périls.
 
 */
public class TableViewRealmFetchAdapter: RealmFetchAdapter {
    
    private weak var    delegate: TableViewRealmFetchAdapterDelegate?
    
    public init(tableDelegate: TableViewRealmFetchAdapterDelegate?,
                realmDelegate: RealmInstanceDelegate?,
                configuration: RealmFetchAdapterConfiguration,
                cacheName: String? = nil,
                debugIdentifier: String = "TVFC") {
        
        self.delegate = tableDelegate
        
        super.init(configuration: configuration,
                   cacheName: cacheName,
                   delegate: tableDelegate,
                   realmDelegate: realmDelegate,
                   debugIdentifier: debugIdentifier)
    }
    
    
    // MARK: Generic actions override for TableView
    override func   controllerDidPerformFetch() {
        //objc_sync_enter(self.blockOperations)
        if Thread.isMainThread == false {
            DispatchQueue.main.sync {
                //DDLogDebug("\(self.debugIdentifier) - controllerDidPerformFetch..")
                self.delegate?.getTableView()?.reloadData()
                self.delegate?.onDidFinishInitialFetch()
            }
        } else {
            //DDLogDebug("\(self.debugIdentifier) - controllerDidPerformFetch..")
            self.delegate?.getTableView()?.reloadData()
            self.delegate?.onDidFinishInitialFetch()
        }
        
        //objc_sync_exit(self.blockOperations)
    }
    override func   reloadData() {
        //objc_sync_enter(self.blockOperations)
        if Thread.isMainThread == false {
            DispatchQueue.main.sync {
                self.delegate?.getTableView()?.reloadData()
            }
        } else {
            self.delegate?.getTableView()?.reloadData()
        }
        //objc_sync_exit(self.blockOperations)
    }
    override func   performOperations() {
        DispatchQueue.main.sync {
            guard let tableView: UITableView = self.delegate?.getTableView() else {
                self.blockOperations.removeAll(keepingCapacity: false)
                objc_sync_exit(self.blockOperations)
                return
            }
            
            if let changeset: StagedChangeset = self.nextChangeSet {
                tableView.reload(
                    using: changeset,
                    with: UITableView.RowAnimation.automatic) { data in
                    // Update reference data when if required
                    self.referenceData = data
                }
            }
            
            //DDLogDebug("\(self.debugIdentifier) - FINISHING - beginUpdates start..")
            /*tableView.beginUpdates()
            self.executeOperations()
            tableView.endUpdates()
            
            self.blockOperations.removeAll(keepingCapacity: false)
            
            //DDLogDebug("\(self.debugIdentifier) - FINISHING - endUpdates finished..")*/
            
            self.delegate?.onFinishedFetchUpdate()
            objc_sync_exit(self.blockOperations)
            
            //objc_sync_exit(self.blockOperations)
            //DDLogDebug("\(self.debugIdentifier) - FINISHED - performBatchUpdates completed..")
        }
    }
    
}
