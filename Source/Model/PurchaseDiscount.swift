/// A `PurchaseDiscount` is made up of parameters that must be generated on an application's server, if you want to apply an available discount for a `Purchase`. The `offerIdentifier` corresponds to the `identifier` of a `SubscriptionTerms.RetentionOffer`.
/// You can supply this `PurchaseDiscount` when you commit a compatible purchase.
public struct PurchaseDiscount {
    public let offerIdentifier: String
    public let keyIdentifier: String
    public let nonce: UUID
    public let timestamp: Date
    public let signature: String
    
    public init(offerIdentifier: String, keyIdentifier: String, nonce: UUID, timestamp: Date, signature: String) {
        self.offerIdentifier = offerIdentifier
        self.keyIdentifier = keyIdentifier
        self.nonce = nonce
        self.timestamp = timestamp
        self.signature = signature
    }
}
