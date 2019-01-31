public protocol MerchantConsumableProductHandler : AnyObject {
    /// Called when a consumable product is purchased. Update your application to accredit the user with the content represented by the product, then call the `completion` handler.
    func merchant(_ merchant: Merchant, consume product: Product, completion: @escaping () -> Void)
}
