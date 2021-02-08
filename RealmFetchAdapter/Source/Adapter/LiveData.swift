//
//  LiveData.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import DifferenceKit
import UIKit


/// IndexedLiveData
struct IndexedLiveData: Equatable {
    
    let resultIndex:    Int
    let id:             String
    let data:           FetchableObject? // To become -> ViewModel
    
    public var hashValue: Int { get { return Int(id) ?? 0 } }
    
    static func == (lhs: IndexedLiveData, rhs: IndexedLiveData) -> Bool {
        return lhs.id == rhs.id
    }
}

typealias LiveIndex = [IndexPath : IndexedLiveData]

/// Model section
struct ModelSection: Differentiable {
    
    typealias Collection = ModelData
    
    let id: String
    
    var differenceIdentifier: String {
        return id
    }
    
    func isContentEqual(to source: ModelSection) -> Bool {
        return id == source.id
    }
}
/// Model Data for Fetchable Object item
struct ModelData: Differentiable {
    let id:     String
    let data:   IndexedLiveData
    
    var differenceIdentifier: String {
        return id
    }
    
    func isContentEqual(to source: ModelData) -> Bool {
        return id == source.id
    }
}

internal typealias FetchObjectSection = ArraySection<ModelSection, ModelData>

/// Live data object represent the current state of an adapter. Use to give last current data to user even if an update is on going
internal class LiveData {
    
    private let index:  LiveIndex
    let arraySections:  [FetchObjectSection]
    let iteration:      UInt
    
    init(index: LiveIndex = [:], iteration: UInt) {
        self.index = index
        self.arraySections = LiveData.arraySection(with: index)
        self.iteration = iteration
    }
    
    private struct RowData {
        let indexPath: IndexPath
        let data: IndexedLiveData
    }
    
    /// Return an arrary of FetchObjectSection
    private class func arraySection(with liveIndex: LiveIndex) -> [FetchObjectSection] {
        var result: [FetchObjectSection] = []
        
        let sectionSet: Set<Int> = Set(liveIndex.keys.map { $0.section })
        
        for sectionIndex in 0..<sectionSet.count {
            var rowDatas: [RowData] = []
            for (index, item) in liveIndex {
                if index.section == sectionIndex {
                    rowDatas.append(RowData(indexPath: index, data: item))
                }
            }
            let sortedRowData = rowDatas.sorted { (a, b) -> Bool in
                return a.indexPath.row < b.indexPath.row
            }
            let objects: [IndexedLiveData] = sortedRowData.map { $0.data }
            
            let sectionId: String = ((objects.first?.data)?.groupfilter) ?? "default" 
            
            var elements: [ModelData] = []
            
            for element in sortedRowData {
                elements.append(ModelData(id: element.data.id, data: element.data))
            }
            let section: FetchObjectSection =
                ArraySection(model:  ModelSection(id: sectionId),
                             elements: elements)
            
            result.append(section)
        }
        
        return result
    }
    
}
