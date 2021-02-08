//
//  DemoTableViewCell.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit
import RealmFetchAdapter


class DemoTableViewCell: UITableViewCell {

    @IBOutlet var lbTitle: UILabel?
    @IBOutlet var lbInfo: UILabel?
    
    private var count: Int = 0
    
    var viewModel: FetchableObject?
    
    override var reuseIdentifier: String? {
        get {
            return "DemoTableViewCell"
        }
    }
    
    func configureUpdate<T>(viewModel: T) where T : FetchableObject {
        self.count += 1
        self.lbInfo?.text = "\(viewModel.id.suffix(5)): \(self.count)"
        
        
        guard let demoViewModel: DemoViewModel = viewModel as? DemoViewModel
            else { return }
        self.viewModel = demoViewModel
        self.contentView.backgroundColor = demoViewModel.color
        
        self.lbTitle?.text = "\(demoViewModel.sort)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lbTitle?.text = ""
        self.lbInfo?.text = ""
        self.contentView.backgroundColor = UIColor.white
    }

}
