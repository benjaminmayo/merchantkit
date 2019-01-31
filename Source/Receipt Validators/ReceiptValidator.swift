public protocol ReceiptValidator {
    func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void)
}
