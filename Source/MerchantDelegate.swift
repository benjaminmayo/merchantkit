/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : AnyObject {
    /// Called when the state of a registered product changes. Update your application state as appropriate. Some applications may be able to implement this delegate method as a no-op, depending on how they are structured.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// Called when the `isLoading` property on the `Merchant` changes. You may want to update UI in response to loading state changes, e.g. show/hide the status bar network activity indicator, or you may want to do nothing. The default implementation of this delegate method does nothing.
    func merchantDidChangeLoadingState(_ merchant: Merchant)
    
    /// Called when a user activates a Promoted In-App Purchase in the App Store, with the intent to buy the `Product`. The default implementation of this delegate method returns `StoreIntentResponse.default` (equal to `StoreIntentResponse.automaticallyCommit`) which begins the purchase flow immediately. You may want to defer the commit until later, in which case your application logic should keep hold of the `Purchase` to use later, and return `StoreIntentResponse.defer`.
    func merchant(_ merchant: Merchant, didReceiveStoreIntentToCommit purchase: Purchase) -> StoreIntentResponse
}

extension MerchantDelegate {
    public func merchantDidChangeLoadingState(_ merchant: Merchant) {
        
    }
    
    public func merchant(_ merchant: Merchant, didReceiveStoreIntentToCommit purchase: Purchase) -> StoreIntentResponse {
        return .default
    }
}
