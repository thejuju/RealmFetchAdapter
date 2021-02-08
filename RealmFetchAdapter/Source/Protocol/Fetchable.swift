//
//  Fetchable.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation


/** Fetchable protocol
    - Need to be implemented on each "Fetchable object"
 */
public protocol Fetchable {

    /// Unique fetechable object identifier
    var id:             String  { get }
    /// Section group filter unique section identifier
    var groupfilter:    String? { get set }
    
    
    /** Compare fetchable object to another, find significant changes
    - important : don't forget to call super.compareSignificantChanges and get the result is a reference
    */
    func    compareSignificantChanges(compareTo other: Self) -> Bool
    
}

/**
    Default implementaiton of Fetchable abstraction
 
    - Note: FetchableObject and Fetchable protocol is an abstraction over the realm object to split logic and avoir to manipulate thread sensitive realm object in a fast enumeration and changes context
 
 */
open class FetchableObject: NSObject, Fetchable {
    
    /// Unique fetechable object identifier
    public let id: String
    /// Section group filter unique section identifier
    public var groupfilter: String?
    
    public init(id: String,
                groupFilter filter: String? = nil) {
        
        self.id = id
        self.groupfilter = filter
    }
    
    open func compareSignificantChanges(compareTo other: FetchableObject) -> Bool {
        return self.id == other.id
    }
    
}

