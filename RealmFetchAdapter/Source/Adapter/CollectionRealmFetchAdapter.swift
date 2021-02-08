//
//  CollectionRealmFetchAdapter.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import UIKit
import DifferenceKit


/// Collection view fetch controller delegate
public protocol CollectionRealmFetchAdapterDelegate: RealmFetchAdapterDelegate {
    
    /// CollectionView to update
    func getCollectionView() -> UICollectionView?
    
}


/**
 Use this controller to automaticaly listen realm fetch request modifications for UICollectionView
 
 - Important : this fetch controller helper is very disapointed when you manipulate reloadData behind it... à vos risque et périls.
 
 */
public class CollectionRealmFetchAdapter: RealmFetchAdapter {
    
    private weak var delegate:  CollectionRealmFetchAdapterDelegate?
    
    //private var diffCalculator:         CollectionViewDiffCalculator<String, String>?
    //private var singleDiffCalculator:   SingleSectionCollectionViewDiffCalculator<String>?
    
    
    public init(collectionDelegate: CollectionRealmFetchAdapterDelegate?,
                realmDelegate: RealmInstanceDelegate?,
                configuration: RealmFetchAdapterConfiguration,
                cacheName: String? = nil,
                debugIdentifier: String = "CVFC") {
        
        self.delegate = collectionDelegate
        
        super.init(configuration: configuration,
                   cacheName: cacheName,
                   delegate: collectionDelegate,
                   realmDelegate: realmDelegate,
                   debugIdentifier: debugIdentifier)
    }
    
    
    // MARK: Generic actions override for CollectionView
    override func   controllerDidPerformFetch() {
        //objc_sync_enter(self.blockOperations)
        if Thread.isMainThread == false {
            DispatchQueue.main.sync {
                //DDLogDebug("\(self.debugIdentifier) - controllerDidPerformFetch..")
                self.delegate?.getCollectionView()?.reloadData()
                self.delegate?.onDidFinishInitialFetch()
            }
        } else {
            //DDLogDebug("\(self.debugIdentifier) - controllerDidPerformFetch..")
            self.delegate?.getCollectionView()?.reloadData()
            self.delegate?.onDidFinishInitialFetch()
        }
    }
    override func   reloadData() {
        //objc_sync_enter(self.blockOperations)
        if Thread.isMainThread == false {
            DispatchQueue.main.sync {
                self.delegate?.getCollectionView()?.reloadData()
            }
        } else {
            self.delegate?.getCollectionView()?.reloadData()
        }
        //objc_sync_exit(self.blockOperations)
    }
    override func   performOperations() {
        DispatchQueue.main.sync {
            guard let collectionView: UICollectionView = self.delegate?.getCollectionView() else {
                objc_sync_exit(self.blockOperations)
                return
            }
            guard let changeset: StagedChangeset = self.nextChangeSet else { return }
            collectionView.reload(
                using: changeset,
                interrupt: { $0.changeCount > 100 }) { data in
                    // Update reference data when if required
                    self.referenceData = data
            }
            
            // Call fetch finished
            self.delegate?.onFinishedFetchUpdate()
            objc_sync_exit(self.blockOperations)
            
            /*collectionView.performBatchUpdates({
                //DDLogDebug("\(self.debugIdentifier) - FINISHING - performBatchUpdates start..")
                
                self.executeOperations()
                self.blockOperations.removeAll(keepingCapacity: false)
            
                //DDLogDebug("\(self.debugIdentifier) - FINISHING - performBatchUpdates finished..")
                
            }, completion: { (sucess) in
                self.delegate?.onFinishedFetchUpdate()
                objc_sync_exit(self.blockOperations)
                //DDLogDebug("\(self.debugIdentifier) - FINISHED - performBatchUpdates completed..")
            })*/
        }
    }
    
}


/// This extension is used to prevent abusive cell reload only if data has changed, fetcher can provide smooth update for custom CollectionViewCell
/*extension UICollectionView {
    
    typealias KeyType = FetchableObject
    
    // fix the blinking bug.. dequeueReusableCell creare new cell each reloadItems..
    func reloadVisibleItems(at datas: [(indexPath: IndexPath, viewModel: FetchableObject)], fetchController: RealmFetchAdapter) {
        var toReloadIndexPath: [IndexPath] = []
        
        var visibleIndexPath: [IndexPath] = []
        
        // Find visible indexpath
        for cell in self.visibleCells {
            if let indexPath = self.indexPath(for: cell) {
                visibleIndexPath.append(indexPath)
            }
        }
        
        // Update cell if needed
        for data in datas {
            if visibleIndexPath.contains(data.indexPath) {
                // Reload content of this cell
                if let cell: FetchedCellProtocol = self.cellForItem(at: data.indexPath) as? FetchedCellProtocol {
                    //if let cell.viewModel?.id == self
                    if let vm: FetchableObject = fetchController.object(at: data.indexPath) {
                        if cell.viewModel?.id == vm.id {
                            cell.configureUpdate(viewModel: vm)
                            continue
                        }
                    }
                }
                
                toReloadIndexPath.append(data.indexPath)
            }
        }
        
        if toReloadIndexPath.count > 0 {
            self.reloadItems(at: toReloadIndexPath)
        }
    }
    
}*/
