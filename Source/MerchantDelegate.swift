/// The delegate for a `Merchant`. All delegate methods are called on the main thread.
public protocol MerchantDelegate : AnyObject {
    /// Called when the state of a registered product changes. Update your application state as appropriate.
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    
    /// Called to authenticate and parse `StoreKit` receipts. Validation work may be synchronous or asynchronous. Call the `completion` handler with a `Result` encapsulating a validated `Receipt` or an `Error`. To implement this method, use a validator included with `MerchantKit` or perform custom logic and call the completion handler.
    func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (_ result: Result<Receipt>) -> Void)

    /// Called when a consumable product is purchased. Update your application to accredit the user with the content represented by the product.
    func merchant(_ merchant: Merchant, didConsume product: Product)
    
    /// Called when the `isLoading` property on the `Merchant` changes. You may want to update UI in response to loading state changes. This delegate method is not required.
    func merchantDidChangeLoadingState(_ merchant: Merchant)
}

extension MerchantDelegate {
    /// Default trapping implementation of `MerchantDelegate.merchant(_:, didConsume:)`. This delegate method must be implemented by an application that allows users to purchase consumable products. It can be ignored if the application only handles non-consumable, or subscription products.
    public func merchant(_ merchant: Merchant, didConsume product: Product) {
        MerchantKitFatalError.raise("Implement `MerchantDelegate.merchant(_:, didConsume:)` to respond to purchases of consumable products. It is a programming error not to explicitly implement the delegate method if the application allows users to purchase consumable products.")
    }
    
    /// Default no-op implementation of `MerchantDelegate.merchantDidChangeLoadingState(_:)`.
    public func merchantDidChangeLoadingState(_ merchant: Merchant) {
        
    }
}
