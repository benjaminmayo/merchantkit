import Foundation

/// Atempts to generate a parsed receipt from the request. Currently, this flow does very little to ensure the receipt is legitimate. It is mostly a parser. If this is unsuitable, you can always make your own `ReceiptValidator`.
public final class LocalReceiptValidator : ReceiptValidator {
    public init() {
        
    }
    
    public func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let receipt = try self.receipt(from: request.data)
                
                completion(.succeeded(receipt))
            } catch let error {
                completion(.failed(error))
            }
        }
    }
}

extension LocalReceiptValidator {
    private func receipt(from receiptData: Data) throws -> Receipt {
        do {
            let container = PKCS7ReceiptDataContainer(receiptData: receiptData)
            let content = try container.content()

            let parser = LocalReceiptPayloadParser()
            
            return try parser.receipt(from: content)
        }
    }
}
