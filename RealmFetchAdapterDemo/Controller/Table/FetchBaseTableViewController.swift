//
//  FetchBaseTableViewController.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter
import RealmSwift


class FetchBaseTableViewController: FetchBaseViewController {
    
    @IBOutlet var tableView:    UITableView?
    var fetchAdapter:           TableViewRealmFetchAdapter?
    
    
    // MARK: Common actions
    @IBAction override func reloadData(id: Any) {
        self.tableView?.reloadData()
    }    
}


// MARK: UITableViewDataSource
extension FetchBaseTableViewController: UITableViewDataSource {
    
    
    func        numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchAdapter?.numberOfSections() ?? 0
    }
    
    func        tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchAdapter?.numberOfRows(forSectionIndex: section) ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: DemoTableViewCell = tableView.dequeueReusableCell(
            withIdentifier: "DemoTableViewCell",
            for: indexPath) as? DemoTableViewCell {
            
            if let viewModel: DemoViewModel = self.fetchAdapter?.object(at: indexPath) as? DemoViewModel {
                cell.configureUpdate(viewModel: viewModel)
            } else {
                cell.lbTitle?.text = "ERROR"
                cell.backgroundColor = UIColor.red
            }
            
            return cell
        }
        return DemoTableViewCell()
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // setup action
        if let viewModel: DemoViewModel = self.fetchAdapter?.object(at: IndexPath(row: 0, section: section)) as? DemoViewModel {
            return viewModel.groupfilter
        }
        return nil
    }
    
}


// MARK: CollectionRealmFetchAdapterDelegate
extension FetchBaseTableViewController: TableViewRealmFetchAdapterDelegate {
    
    func getTableView() -> UITableView? {
        return self.tableView
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

