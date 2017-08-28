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
