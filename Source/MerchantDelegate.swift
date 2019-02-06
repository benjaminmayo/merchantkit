/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : AnyObject {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// Called when the `isLoading` property on the `Merchant` changes. You may want to update UI in response to loading state changes, or you may want to do nothing.
    func merchantDidChangeLoadingState(_ merchant: Merchant)
    
    /// Called when a user activates a Promoted In-App Purchase in the App Store, with the intent to buy the `Product`. The default implementation of this delegate method returns `StoreIntentResponse.default` (equal to `StoreIntentResponse.automaticallyCommit`) which begins the purchase flow immediately. You may want to defer the commit until later, in which case your application logic should keep hold of the `Purchase` to use later, and return `StoreIntentResponse.defer`.
    func merchant(_ merchant: Merchant, storeIntentDidRequestCommit purchase: Purchase) -> StoreIntentResponse
}

extension MerchantDelegate {
    func merchant(_ merchant: Merchant, storeIntentDidRequestCommit purchase: Purchase) -> StoreIntentResponse {
        return .default
    }
}
