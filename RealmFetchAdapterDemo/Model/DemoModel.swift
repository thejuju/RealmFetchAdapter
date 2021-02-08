//
//  DemoModel.swift
//  RealmFetchAdapterDemo
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import RealmSwift
import RealmFetchAdapter
import UIKit


class DemoModel: RealmSwift.Object {
    
    @objc public dynamic var id:                    String = UUID().uuidString
    @objc public dynamic var sort:                  Int = 0
    @objc public dynamic var section:               String?
    @objc public dynamic var color:                 String = "#FFFFFF"
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    func setColor(_ new: UIColor) {
        self.color = new.hexString
    }
    func getColor() -> UIColor {
        return UIColor(hexString: self.color)
    }

}


public class DemoViewModel: FetchableObject {
    
    var sort: Int
    var color: UIColor
    
    public func compareSignificantChanges<T>(compareTo other: T) -> Bool where T : Fetchable {
        return true
    }
    
    init(from object: DemoModel) {
        self.sort = object.sort
        self.color = object.getColor()
        super.init(id: object.id)
        self.groupfilter = object.section
    }
    
}
