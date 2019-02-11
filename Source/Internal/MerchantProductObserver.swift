internal protocol MerchantProductPurchaseObserver : AnyObject {
    func merchant(_ merchant: Merchant, didFinishPurchaseWith result: Result<Void, Error>, forProductWith productIdentifier: String)
    
    func merchant(_ merchant: Merchant, didCompleteRestoringProductsWith result: Result<Void, Error>)
}
