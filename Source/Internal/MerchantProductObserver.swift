internal protocol MerchantPurchaseObserver : AnyObject {
    func merchant(_ merchant: Merchant, didCompletePurchaseForProductWith productIdentifier: String)
    func merchant(_ merchant: Merchant, didFailPurchaseWith error: Error, forProductWith productIdentifier: String)
}
