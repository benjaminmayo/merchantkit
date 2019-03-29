/// A request for a `ReceiptValidator` to handle. Validators can inspect the `reason` to handle validation differently at different stages. For instance, a testing validator may want to fail, on purpose, during initialization.
public struct ReceiptValidationRequest {
    public let data: Data
    public let reason: Reason
    
    internal init(data: Data, reason: Reason) {
        self.data = data
        self.reason = reason
    }
}

extension ReceiptValidationRequest {
    public enum Reason {
        case completePurchase
        case initialization
        case restorePurchases
    }
}
