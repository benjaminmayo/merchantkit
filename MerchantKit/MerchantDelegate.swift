/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : class {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// This delegate method is called to authenticate and parse `StoreKit` receipts. Validation work may be synchronous or asynchronous. Call the `completion` handler with a Result encapsulating a validated `Receipt` or an `Error`. Use your own validation methods or create an instance of a validator included with `MerchantKit`.
    func merchant(_ merchant: Merchant, validate receiptData: Data, completion: @escaping (_ result: Result<Receipt>) -> Void)
}
