internal class TestingReceiptValidator : ReceiptValidator {
    private let wrapping: ReceiptValidator
    
    init(wrapping validator: ReceiptValidator) {
        self.wrapping = validator
    }
    
    func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt, Swift.Error>) -> Void) {
        if request.reason == .initialization {
            completion(.failure(Error.failingInitializationOnPurposeForTesting))
        } else {
            self.wrapping.validate(request, completion: completion)
        }
    }
    
    private enum Error : Swift.Error {
        case failingInitializationOnPurposeForTesting
    }
}
