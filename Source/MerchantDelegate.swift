/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : AnyObject {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// Called when the `isLoading` property on the `Merchant` changes. You may want to update UI in response to loading state changes, or you may want to do nothing.
    func merchantDidChangeLoadingState(_ merchant: Merchant)
}
