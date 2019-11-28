internal protocol StoreInterface : AnyObject {
    func setup(withDelegate delegate: StoreInterfaceDelegate)

    func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher
    func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher
    
    func commitPurchase(_ purchase: Purchase, with discount: PurchaseDiscount?, using storeParameters: StoreParameters)
    func restorePurchases(using storeParameters: StoreParameters)
}
