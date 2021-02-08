//
//  RealmInstanceDelegate.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import RealmSwift


/** Realm instance dedicated delegate
    - mandatory to provide a valid realm instance
 */
public protocol RealmInstanceDelegate: class {
    
    /** Working instance of Realm
     - note: the instance was invalidated by the adapter automaticaly
     */
    var realm: Realm { get }
    
}
