internal protocol StoreInterfaceDelegate : AnyObject {
    func storeInterfaceWillUpdatePurchases(_ storeInterface: StoreInterface)
    func storeInterfaceDidUpdatePurchases(_ storeInterface: StoreInterface)
    
    func storeInterfaceWillStartRestoringPurchases(_ storeInterface: StoreInterface)
    func storeInterface(_ storeInterface: StoreInterface, didFinishRestoringPurchasesWith result: Result<Void, Error>)
    
    func storeInterface(_ storeInterface: StoreInterface, didPurchaseProductWith productIdentifier: String, completion: @escaping () -> Void)
    func storeInterface(_ storeInterface: StoreInterface, didFailToPurchaseProductWith productIdentifier: String, error: Error)
    func storeInterface(_ storeInterface: StoreInterface, didRestorePurchaseForProductWith productIdentifier: String)
    
    func storeInterface(_ storeInterface: StoreInterface, responseForStoreIntentToCommitPurchaseFrom source: Purchase.Source) -> StoreIntentResponse
}
