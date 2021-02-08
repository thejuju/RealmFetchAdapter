//
//  DemoHeaderCollectionReusableView.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import UIKit


class DemoHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet var lbTitle: UILabel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lbTitle?.text = ""
    }
}
