/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : class {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStateFor products: Set<Product>)
    
    /// Called to authenticate and parse `StoreKit` receipts. Validation work may be synchronous or asynchronous. Call the `completion` handler with a `Result` encapsulating a validated `Receipt` or an `Error`. Use your own validation methods or create an instance of a validator included with `MerchantKit`.
    func merchant(_ merchant: Merchant, validate receiptData: Data, completion: @escaping (_ result: Result<Receipt>) -> Void)

    /// Called when the `isLoading` property on the `Merchant` changes. You may want to update UI in response to loading state changes. This delegate method is not required.
    func merchantDidChangeLoadingState(_ merchant: Merchant)
}

extension MerchantDelegate {
    /// Default no-op implementation of `MerchantDelegate.merchantDidChangeLoadingState(_:)`.
    public func merchantDidChangeLoadingState(_ merchant: Merchant) {
        
    }
}
