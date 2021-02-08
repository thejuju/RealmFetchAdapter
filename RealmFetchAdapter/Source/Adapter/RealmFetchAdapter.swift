//
//  RealmFetchAdapter.swift
//  RealmFetchAdapter
//
//  Created by Julien Bignon on 01/15/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import DifferenceKit

/*
 
 - Mono section only:  mention to section on this class is only convenient or useless and soon refactored
 - sectionKeyPath explaination: this option group result on an array for the keyPath setted
 Ex:
 Dataset: A:1 B:2 C:1 D:1 E:3 F:2
 Return results: [[A,C,D], [B,F], [C]]
 
 Without keypath the returned result is [[A],[B],[C],[D],[E],[F]]
 
 */

/*
 GCD inspiration : https://stackoverflow.com/questions/41819435/realm-notification-token-on-background-thread
 thx https://stackoverflow.com/users/2340687/thomas-goyne
 
 */


public class RealmFetchAdapter: NSObject {
    
    internal var            blockOperations:    [BlockOperation] = []
    /// Next changeset to be applied
    internal var            nextChangeSet:      StagedChangeset<[FetchObjectSection]>?
    /// Next liveData to be applied
    //internal var            nextLiveData:       LiveData?
    
    /// Reference data collection
    internal var            referenceData:      [FetchObjectSection] = []
    
    
    private weak var        delegate:           RealmFetchAdapterDelegate?
    private weak var        realmDelegate:      RealmInstanceDelegate?
    
    fileprivate var         debugIdentifier: String
    private var             isFetchPaused: Bool = false
    
    fileprivate var         configuration: RealmFetchAdapterConfiguration? = nil
    private var             lastPerformedConfiguration: RealmFetchAdapterConfiguration? = nil
    
    fileprivate var         section: Int = 0
    
    /// Last live data (reference for collection view)
    private var             liveDataSource:     LiveData = LiveData(iteration: 0)
    //private var             liveDataIteration: UInt = 0
    public var              liveDataIteration: UInt = 0
    
    /// Last live data results
    // ??? fileprivate weak var    liveDataResult: RealmSwift.Results<RealmSwift.Object>?
    fileprivate var    liveDataResult: RealmSwift.Results<RealmSwift.Object>?
    
    /// Notify if live data controller need a full reload data, eq. after a skipped turn of update
    fileprivate var         needLiveReloadData: Bool = false
    
    public var              isLoading: Bool = true // initialy true, prevent empty state before first load
    
    
    public init(configuration: RealmFetchAdapterConfiguration,
                cacheName: String? = nil,
                delegate: RealmFetchAdapterDelegate?,
                realmDelegate: RealmInstanceDelegate?,
                debugIdentifier: String = "CVFC") {
        
        self.delegate = delegate
        self.realmDelegate = realmDelegate
        self.debugIdentifier = debugIdentifier
        
        super.init()
        
        self.setup(configuration: configuration)
    }
    
    private var         fetchNotificationToken: RealmSwift.NotificationToken?
    private weak var    fetchNotificationRunLoop: CFRunLoop?
    
    
    private func        setup(configuration: RealmFetchAdapterConfiguration) {
        self.isLoading = true
        self.configuration = configuration
        self.section = configuration.section
        self.needLiveReloadData = false
        
        self.fetchNotificationToken?.invalidate()
        if let runloop = self.fetchNotificationRunLoop {
            CFRunLoopStop(runloop)
        }
        self.fetchNotificationToken = nil
        self.referenceData = LiveData(index: [:], iteration: 0).arraySections
    }
    
    public func         setNewConfiguration(_ configuration: RealmFetchAdapterConfiguration) {
        self.setup(configuration: configuration)
    }
    
    private class func  getMainFetchRequest(realm: RealmSwift.Realm,
                                            rlmClassObject: RealmSwift.Object.Type,
                                            predicate: NSPredicate,
                                            sortDescriptors: [RealmSwift.SortDescriptor]) -> RealmSwift.Results<RealmSwift.Object> {
        
        var fetchResults = realm.objects(rlmClassObject).filter(predicate)
        //var fetchResults = rlmClassObject.allObjects(in: realm).objects(with: predicate) as! RealmSwift.Results<RealmSwift.Object>
    
        // If we have sort descriptors then use them
        if (sortDescriptors.count > 0) {
            fetchResults = fetchResults.sorted(by: sortDescriptors)
        }
        
        return fetchResults
    }
    
    
    /**
     Launch an update live data if available, cause a reloadData of collection if new data if available
     
     - see: canUpdateLiveData
     
     */
    public func     requestUpdateLiveData() {
        
        guard self.needLiveReloadData == true else { return }
        guard let dataResult = self.liveDataResult else { return }
        guard let runLoop: CFRunLoop = self.fetchNotificationRunLoop else { return }
        
        self.referenceData = LiveData(index: [:], iteration: 0).arraySections
        self.reloadData()
        
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue, {
            let newLiveData: LiveData = self.buildLiveData(for: dataResult)
            self.handleInitialResults(newLiveData: newLiveData)
        })
        
    }
    private func    performeFetchIfNeeded() -> Bool {
        
        guard self.lastPerformedConfiguration != self.configuration
            && self.fetchNotificationToken == nil else {
                // Already fetched ! do nothing
                print("\(self.debugIdentifier) - performeFetchIfNeeded: Already fetched)")
                return false
        }
        
        //DDLogDebug("\(self.debugIdentifier) - performeFetchIfNeeded starting")
        
        // Prevent fetching without valid configuration
        guard let currentConfiguration: RealmFetchAdapterConfiguration = self.configuration else {
            return false
        }
        

        // Cancel previous runloop
        if let runloop = self.fetchNotificationRunLoop {
            CFRunLoopStop(runloop)
        }
        
        // unlock in case of re-set
        objc_sync_exit(self.blockOperations)
        
        // Be aware to use *weak* reference of *self* or all the FetchController instanciated can cause a concurent exception
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            // Capture a reference to the runloop so that we can stop running it later
            self?.fetchNotificationRunLoop = CFRunLoopGetCurrent()
            
            guard let runLoop: CFRunLoop = self?.fetchNotificationRunLoop else {
                return
            }
            
            CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
                
                guard let realm: RealmSwift.Realm = self?.realmDelegate?.realm else { return }
                
                // Initialize main fetch results with predicate
                let fetchResults = RealmFetchAdapter.getMainFetchRequest(
                    realm: realm,
                    rlmClassObject: currentConfiguration.entityType,
                    predicate: currentConfiguration.predicate,
                    sortDescriptors: currentConfiguration.sortDescriptors)
                
                // Add the notification from within a block executed by the
                // runloop so that Realm can verify that there is actually a
                // runloop running on the current thread
                
                //self?.fetchNotificationToken = fetchResults.addNotificationBlock { (result, change, error) in
                //}) { (result, change, error) in
                self?.fetchNotificationToken = fetchResults.observe({ (change) in
                    
                    switch change {
                    case .error(let error):
                        
                        print("RLMFA ERROR: \(error.localizedDescription)")
                        // handle error !!
                        //DDLogDebug("\(self?.debugIdentifier ?? "none") - error:\(String(describing: error))")
                        //objc_sync_exit(self!.blockOperations)
                        return
                    case .initial(let dataResult):
                        
                        let newLiveData: LiveData = self?.buildLiveData(for: dataResult) ?? LiveData(iteration: self?.liveDataIteration ?? 0)
                        self?.handleInitialResults(newLiveData: newLiveData)
                        
                        break
                    case .update(let dataResult,_,_,_):
                        
                        let newLiveData: LiveData = self?.buildLiveData(for: dataResult) ?? LiveData(iteration: self?.liveDataIteration ?? 0)
                        
                        // Save last result
                        self?.liveDataResult = dataResult
                        
                        // Check if live reload data is already requested
                        guard self?.needLiveReloadData == false else {
                            // Notify
                            DispatchQueue.main.sync {
                                self?.delegate?.newLiveDataIsAvailable()
                            }
                            
                            return
                        }
                        
                        // Block operations queue NOT USED YET
                        //objc_sync_enter(self!.blockOperations)
                        
                        DispatchQueue.main.sync {
                            self?.delegate?.onBeginFetchUpdate()
                        }
                        
                        // Check empty result to fast cleanning by reload data if needed.
                        if dataResult.count == 0 {
                            // assume reload data and quit process
                            //self?.liveData.index.removeAll()
                            self?.referenceData = LiveData(index: [:], iteration: 0).arraySections
                            self?.reloadData()
                            self?.isLoading = false
                            self?.controllerDidPerformFetch()
                            //objc_sync_exit(self!.blockOperations)
                            return
                        }
                        
                        // ALL TIME RELOAD DATA.... IN CASE OF ERROR...
                        /*self?.referenceData = newLiveData.arraySections
                        self?.reloadData()
                        self?.isLoading = false
                        self?.controllerDidPerformFetch()
                        //objc_sync_exit(self!.blockOperations)
                        return*/
                    
                        // DifferenceKit
                        let source = self!.referenceData
                        let target = newLiveData.arraySections
                        let stagedChangeset = StagedChangeset(source: source, target: target)
                        self?.nextChangeSet = stagedChangeset
                        
                        /*print("\nFETCH: RUN-")
                        print("FETCH: Listing OLD : \(self!.liveDataIteration-1)")
                        print("FETCH: Listing NEW \(newLiveData.iteration)")
                         
                        for (index, changeset) in stagedChangeset.enumerated() {
                            print("FETCH: changeset #\(index)")
                            print("FETCH: changeset S(D:I:M)\(changeset.sectionDeleted):\(changeset.sectionInserted):\(changeset.sectionMoved)")
                            print("FETCH: changeset E(D:I:M:U)\(changeset.elementInserted):\(changeset.elementDeleted):\(changeset.elementMoved):\(changeset.elementUpdated)")
                        }
                        
                        var sourceSection: String = "FETCH: SOURCE;"
                        for (index, data) in source.enumerated() {
                            sourceSection.append("#\(index): \(data.differenceIdentifier);")
                        }
                        print(sourceSection)
                        var targetSection: String = "FETCH: TARGET;"
                        for (index, data) in target.enumerated() {
                            targetSection.append("#\(index): \(data.differenceIdentifier);")
                        }
                        print(targetSection)*/
                        
                        // Add common processing block
                        // **  NOT USED YET **//
                        self?.addProcessingBlock {
                        }
                        
                        // Execute update
                        // Specific operations
                        if self?.blockOperations.count ?? 0  > 0 {
                            self?.performOperations()
                        }
                        
                        // Finishing
                        return
                    }
   
                }) // fetchResults.observe --end
            } // CFRunLoopPerformBlock --end
            
            // Run the runloop on this thread until we tell it to stop
            CFRunLoopRun()
        }
        
        //DDLogDebug("\(self.debugIdentifier) -  notification token: \(self.fetchNotificationToken?.debugDescription ?? "none")")
        
        return true
    }
    
    
    // MARK: Tools
    /// Return live data
    /*internal var  liveData: LiveData {
        get {
            return self.liveDataSource
        }
        set {
            self.liveDataSource = newValue
        }
    }*/
    /// Return an corresponding index+viewModel array (in main section) for a index array
    private class func  indexedViewModels(from indexArray: [NSNumber],
                                          section: Int,
                                          in result: RealmSwift.Results<RealmSwift.Object>,
                                          delegate: RealmFetchAdapterDelegate?) -> [IndexedLiveData] {
        
        var indexedViewModel: [IndexedLiveData] = []
        
        for row in indexArray {
            let indexPath = IndexPath(row: Int(truncating: row), section: section)
            
            guard result.count > UInt(truncating: row) else {
                break
            }
            
            let index = UInt(truncating: row)
            let object: RealmSwift.Object = result[Int(index)]
            // ??? result.object(at: UInt(truncating: row))
            
            if let fetchableObject: FetchableObject = RealmFetchAdapter.convenientViewModel(
                realmObject: object,
                indexPath: indexPath,
                delegate: delegate) {
                indexedViewModel.append(IndexedLiveData(resultIndex: Int(truncating: row),
                                                        id: fetchableObject.id,
                                                        data: fetchableObject))
            }
            
        }
        
        return indexedViewModel
    }
    
    /// Convenient, viewModel from RealmSwift.Object
    private class func  convenientViewModel(realmObject: RealmSwift.Object,
                                            indexPath: IndexPath,
                                            delegate: RealmFetchAdapterDelegate?) -> FetchableObject? {
        
        let viewModel: FetchableObject? = delegate?.getViewModel(for: realmObject)
        
        return viewModel
    }
    
    private func        convenientViewModelArray(realmObjects: RealmSwift.Results<RealmSwift.Object>) -> LiveIndex {
        var dict: LiveIndex = [:]
        
        for (index, object) in realmObjects.enumerated() {
            
            // AUCUNE NOTION DE SECTION ICI
            let indexPath = IndexPath(row: index, section: self.section)
            
            if let viewModel: FetchableObject = RealmFetchAdapter.convenientViewModel(realmObject: object,
                                                                              indexPath: indexPath,
                                                                              delegate: self.delegate) {
                dict[indexPath] = IndexedLiveData(resultIndex: index,
                                                  id: viewModel.id,
                                                  data: viewModel)
            }
        }
        
        return dict
    }
    
    // MARK: Primary data actions
    /// Requreted objects dict
    private typealias RequestedObjects = [String : Int]
    /// Update live data (on ViewModel) for a results
    private func    buildLiveData(for results: RealmSwift.Results<RealmSwift.Object>) -> LiveData {
        
        //let startLightTime: TimeInterval = NSDate().timeIntervalSince1970
        // build reference index
        if  self.configuration?.isSectionned == true,
            let keyPath: String = self.configuration?.sectionNameKeyPath {
            
            // Build result request index
            var requestObjectIndexes: RequestedObjects = [:]
            
            for (index, object) in results.enumerated() {
                guard let viewModel: FetchableObject = self.delegate?.getViewModel(for: object) else { continue }
                requestObjectIndexes[viewModel.id] = index
            }
            
            // Distinct objects by row
            let allValues: [String] = (results.value(forKeyPath: keyPath) as? [String]) ?? []
            var distinctValue: [String] = []
            for value in allValues {
                if distinctValue.contains(value) == false {
                    distinctValue.append(value)
                }
            }
        
            var preLiveData: LiveIndex = [:]
            
            for (section, uniqueValue) in distinctValue.enumerated() {
                // Find all object matching with the keypath value with default sort descriptor
                let matchObjects = results.filter(
                    NSPredicate(format: "\(keyPath) == %@", uniqueValue))
                    .sorted(by: self.configuration?.sortDescriptors ?? [])
                
                // Soucis ici perte de référence d'index...
                // 1 Req = 1 VM sinon perte d'index // result
                // USE let index: Int = results.index(of: matchObjects)
                
                for (row, object) in matchObjects.enumerated() {
                    guard let viewModel: FetchableObject = self.delegate?.getViewModel(for: object),
                        let requestIndex: Int = requestObjectIndexes[viewModel.id] else { continue }
                    let indexPath: IndexPath = IndexPath(row: row, section: section)
                    viewModel.groupfilter = uniqueValue
                    preLiveData[indexPath] = IndexedLiveData(resultIndex: requestIndex,
                                                             id: viewModel.id,
                                                             data: viewModel)
                }
            }
            self.liveDataIteration = self.liveDataIteration + 1
            return LiveData(index: preLiveData, iteration: self.liveDataIteration)
    
            //let runningLightTime: TimeInterval = NSDate().timeIntervalSince1970 - startLightTime
            //print("PERF: updateLiveData (keypath) duration:\(runningLightTime)")
        } else {
            // One object by row
            self.liveDataIteration = self.liveDataIteration + 1
            return LiveData(index: self.convenientViewModelArray(realmObjects: results),
                            iteration: self.liveDataIteration)
           
            //let runningLightTime: TimeInterval = NSDate().timeIntervalSince1970 - startLightTime
            //print("PERF: updateLiveData duration:\(runningLightTime)")
        }
    }
    /// Handle initial results
    private func    handleInitialResults(newLiveData: LiveData) {
        //DDLogDebug("\(self.debugIdentifier) - Fetch initial results: \(newLiveData.count)")
        self.referenceData = newLiveData.arraySections
        self.isLoading = false
        self.controllerDidPerformFetch()
    }
    
    
    // MARK: Generic actions
    internal func   reloadData() {
        // Override
    }
    /// Do not call super performOperations() thread lock issues
    internal func   performOperations() {
        // Override
    }
    internal func   deleteItems(at indexPaths: [IndexPath]) {
        // Override
    }
    internal func   insertItems(at indexPaths: [IndexPath]) {
        // Override
    }
    internal func   reloadItems(at indexPaths: [IndexPath]) {
        // Override
    }
    internal func   insertSections(at indexSet: IndexSet) {
        // Override
    }
    internal func   moveItem(at: IndexPath, to: IndexPath) {
        // Override
    }
    internal func   moveSection(section: Int, toSection: Int) {
        // Override
    }
    internal func   reloadSections(at indexSet: IndexSet) {
        // Override
    }
    internal func   deleteSections(at indexSet: IndexSet) {
        // Override
    }
    
    
    // MARK: Operations helper
    /// Execute all stacked operations
    internal func   executeOperations() {
        //DDLogDebug("\(self.debugIdentifier) - executeOperations will execute: \(self.blockOperations.count) operation(s)..")
        //objc_sync_enter(self.blockOperations)
        for operation in self.blockOperations {
            if operation.isExecuting == false
                && operation.isFinished == false {
                operation.start()
            }
        }
        //objc_sync_exit(self.blockOperations)
    }
    // Use this method to add a fetch operation
    private func    addProcessingBlock(processingBlock:@escaping ()->Void) {
        self.blockOperations.append(BlockOperation(block: processingBlock))
    }
    /// Delete finished operations of queue
    private func    deleteFinishedOperations() {
        
        // NaN
        //self.blockOperations.removeAll(keepingCapacity: false)
    }
    
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch() {
        // override me
    }
    
    
    // MARK: Public action
    public func             pauseFetchController() {
        /*objc_sync_enter(self.blockOperations)
         guard self.isFetchPaused == false else {
         objc_sync_exit(self.blockOperations)
         return
         }
         
         self.isFetchPaused = true
         
         self.blockOperations.removeAll(keepingCapacity: false)
         objc_sync_exit(self.blockOperations)*/
    }
    public func             restartFetchController() {
        /* //objc_sync_enter(self.blockOperations)
         guard self.isFetchPaused == true else {
         objc_sync_exit(self.blockOperations)
         return
         }
         
         self.fetchResultController.reset()
         self.blockOperations.removeAll(keepingCapacity: false)
         //self.delegate?.getCollectionView()?.reloadData()
         objc_sync_exit(self.blockOperations)
         
         self.isFetchPaused = false*/
    }
    /// Stop FetchController, clean configuration and runLoop
    public func             stop() {
        self.configuration = nil
        self.fetchNotificationToken?.invalidate()
        if let runloop = self.fetchNotificationRunLoop {
            CFRunLoopStop(runloop)
        }
        self.fetchNotificationToken = nil
        self.referenceData = LiveData(index: [:], iteration: 0).arraySections
    }
    
    
    // MARK: Public datas
    public var      fetchedObjectsCount: Int {
        get {
            return self.referenceData.reduce(0) { (r, section) -> Int in
                return r+section.elements.count
            }
        }
    }
    public func     numberOfRows(forSectionIndex index: Int) -> Int {
        // TODO: Check out of bounds...
        guard index < self.referenceData.count else { return 0 }
        
        return self.referenceData[index].elements.count
    }
    public func     numberOfSections() -> Int {
        return self.referenceData.count
    }
    public func     object(at indexPath: IndexPath) -> FetchableObject? {
        
        // TODO: Check out of bounds...
        
        guard let viewModel: FetchableObject = self.referenceData[indexPath.section].elements[indexPath.row].data.data else {
            print("FETCH: reqobj: \(indexPath.row).\(indexPath.section) - NONE")
            return nil
        }
        //print("FETCH: reqobj: \(indexPath.row).\(indexPath.section) - \(viewModel.id)")
        return viewModel
    }
    public func     objects(in section: Int) -> [FetchableObject] {
        let objectsSection: [ModelData] = self.referenceData[section].elements
        
        let fetchableObjects: [FetchableObject] = objectsSection.compactMap { $0.data.data }
       
        return fetchableObjects
    }
    public func     objectInMainSection(atIndex index: Int) -> FetchableObject? {
        let indexPath = IndexPath(row: index, section: self.configuration?.section ?? 0)
        return self.object(at: indexPath)
    }
    /// Perform fetch (once by configuration
    public func     performFetch() -> Bool {
        return self.performeFetchIfNeeded()//self.fetchResultController.performFetch()
    }
    /// Get live data, only for jedi knight usage !
    public var      fetchObjectIdentifier: [String] {
        get {
            return self.referenceData.reduce([]) { (r, section) -> [String] in
                let datas: [String] = section.elements.map { $0.data.id }
                return r+datas
            }
        }
    }
    /// Get all fetched object
    public var      fetchedObjects: [FetchableObject] {
        get {
            return self.referenceData.reduce([]) { (r, section) -> [FetchableObject] in
                let datas: [FetchableObject] = section.elements.compactMap { $0.data.data }
                return r+datas
            }
        }
    }
    /// Get indexpath for an object, NOT IMPLEMENTED YET
    open func       indexPath(forObject object: RealmSwift.ObjectBase) -> IndexPath? {
        return nil//self.fetchResultController.indexPath(forObject: object)
    }
    /// Get subset of current (last) result (ex: search), you remain responsible to handle changes on main set
    public func     objects(with predicate: NSPredicate) -> [FetchableObject] {
        
        // Prevent fetching without valid configuration
        guard let currentConfiguration: RealmFetchAdapterConfiguration = self.configuration else {
            return []
        }
        
        guard let realm: RealmSwift.Realm = self.realmDelegate?.realm else { return  [] }
        
        let results = RealmFetchAdapter.getMainFetchRequest(
            realm: realm,
            rlmClassObject: currentConfiguration.entityType,
            predicate: currentConfiguration.predicate,
            sortDescriptors: currentConfiguration.sortDescriptors)
        
        defer {
            results.realm?.invalidate()
        }
        
        // Match root object
        let search = results.filter(predicate)
        
        // Match view model
        return convenientViewModelArray(realmObjects: search).compactMap { $0.value.data }
    }

    
    // MARK: de init
    deinit {
        print("Deinit FetchViewController: \(self.debugIdentifier)")
        
        //objc_sync_enter(self.blockOperations)
        // Cancel all block oper)ations when VC deallocates
        for operation in self.blockOperations {
            operation.cancel()
        }
        
        self.blockOperations.removeAll()
        //objc_sync_exit(self.blockOperations)
        
        
        self.fetchNotificationToken?.invalidate()
        if let runloop = self.fetchNotificationRunLoop {
            CFRunLoopStop(runloop)
        }
        
        objc_sync_exit(self.blockOperations)
    }
    
}
