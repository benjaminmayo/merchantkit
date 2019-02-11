internal protocol StoreInterface : AnyObject {
    func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher
    
    func observeTransactions(withDelegate delegate: StoreKitTransactionObserverDelegate)
    func stopObservingTransactions()
    
    func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher
    func commitPurchase(_ purchase: Purchase, using storeParameters: StoreParameters)
    func restorePurchases(using storeParameters: StoreParameters)
}
