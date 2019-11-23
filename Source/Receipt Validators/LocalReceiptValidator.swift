import Foundation

/// Atempts to generate a parsed receipt from the request. Currently, this flow does very little to ensure the receipt is legitimate. It is mostly a parser. If this is unsuitable, you can always make your own `ReceiptValidator`.
public final class LocalReceiptValidator : ReceiptValidator {
    public init() {
        
    }
    
    public var subscriptionRenewalLeeway: ReceiptValidatorSubscriptionRenewalLeeway = .default
    
    public func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let decoder = LocalReceiptDataDecoder()
                let receipt = try decoder.decode(request.data)
                
                completion(.success(receipt))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
