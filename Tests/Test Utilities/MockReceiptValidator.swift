import MerchantKit

class MockReceiptValidator : ReceiptValidator {
    typealias ValidateRequestHandler = ((_ request: ReceiptValidationRequest, _ completion: @escaping (Result<Receipt, Error>) -> Void) -> Void)

    var validateRequest: ValidateRequestHandler!
    
    init() {
        
    }
    
    var subscriptionRenewalLeeway: ReceiptValidatorSubscriptionRenewalLeeway = .default
    
    func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt, Error>) -> Void) {
        self.validateRequest(request, completion)
    }
}
