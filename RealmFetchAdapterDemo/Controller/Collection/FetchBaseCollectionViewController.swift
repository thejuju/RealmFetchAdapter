//
//  FetchBaseCollectionViewController.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter
import RealmSwift


class FetchBaseCollectionViewController: FetchBaseViewController {

    var fetchAdapter: CollectionRealmFetchAdapter?
    
    @IBOutlet var collectionView: UICollectionView?
    
   
    // MARK: Common actions
    @IBAction override func reloadData(id: Any) {
        self.collectionView?.reloadData()
    }
    
}


// MARK: UICollectionViewDataSource
extension FetchBaseCollectionViewController: UICollectionViewDataSource {
    
    func        numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchAdapter?.numberOfSections() ?? 0
    }
    
    func        collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchAdapter?.numberOfRows(forSectionIndex: section) ?? 0
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView: DemoHeaderCollectionReusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: "DemoHeaderCollectionReusableView",
                for: indexPath) as? DemoHeaderCollectionReusableView else {
                    return UICollectionReusableView()
            }
            
            // setup action
            if let viewModel: DemoViewModel = self.fetchAdapter?.object(at: indexPath) as? DemoViewModel {
                headerView.lbTitle?.text = viewModel.groupfilter
            }
            
            return headerView
        default: break
            //            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
}


// MARK: UICollectionViewDelegate
extension FetchBaseCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell: DemoCollectionViewCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DemoCollectionViewCell",
            for: indexPath) as? DemoCollectionViewCell {
            
            
            if let viewModel: DemoViewModel = self.fetchAdapter?.object(at: indexPath) as? DemoViewModel {
                cell.configureUpdate(viewModel: viewModel)
            } else {
                cell.lbTitle?.text = "ERROR"
                cell.backgroundColor = UIColor.red
            }
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
}


// MARK: CollectionRealmFetchAdapterDelegate
extension FetchBaseCollectionViewController: CollectionRealmFetchAdapterDelegate {
    
    func getCollectionView() -> UICollectionView? {
        return self.collectionView
    }
    
    func onBeginFetchUpdate() {
        print("onBeginFetchUpdate")
    }
    
    func onFinishedFetchUpdate() {
        print("onFinishedFetchUpdate")
    }
    
    func onDidFinishInitialFetch() {
        print("onDidFinishInitialFetch")
    }
    
    func getViewModel(for object: RealmSwift.Object) -> FetchableObject? {
        guard let demoModel: DemoModel = object as? DemoModel else { return nil }
        return DemoViewModel(from: demoModel)
    }
    
    func canUpdateLiveData(changes: FetchControllerDataChange) -> Bool {
        return true
    }
    
    func newLiveDataIsAvailable() {
        
    }
    
}

