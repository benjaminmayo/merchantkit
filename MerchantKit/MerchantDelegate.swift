/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : class {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// This delegate method is called to authenticate and parse `StoreKit` receipts. Validation work may be synchronous or asynchronous. Call the `completion` handler with a Result encapsulating a validated `Receipt` or an `Error`. Use your own validation methods or create an instance of a validator included with `MerchantKit`.
    func merchant(_ merchant: Merchant, validate receiptData: Data, completion: @escaping (_ result: Result<Receipt>) -> Void)
    
    /// A central place where errors are propagated when encountered by the `Merchant`. There is no expectation that these errors need to be handled but it may come in useful when logging/debugging. A no-op default implementation of this method is provided.
    func merchant(_ merchant: Merchant, didEncounter error: Error, in category: ErrorCategory)
}

public extension MerchantDelegate {
    func merchant(_ merchant: Merchant, didEncounter error: Error, in category: ErrorCategory) {
        // Empty default implementation of `MerchantDelegate`
    }
}
