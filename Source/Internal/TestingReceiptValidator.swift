internal class TestingReceiptValidator : ReceiptValidator {
    private let wrapping: ReceiptValidator
    
    internal init(wrapping validator: ReceiptValidator) {
        self.wrapping = validator
    }

    internal var subscriptionRenewalLeeway: ReceiptValidatorSubscriptionRenewalLeeway {
        return self.wrapping.subscriptionRenewalLeeway
    }
    
    internal func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt, Swift.Error>) -> Void) {
        if request.reason == .initialization {
            completion(.failure(Error.failingInitializationOnPurposeForTesting))
        } else {
            self.wrapping.validate(request, completion: completion)
        }
    }
    
    internal enum Error : Swift.Error {
        case failingInitializationOnPurposeForTesting
    }
}
