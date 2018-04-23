import Foundation

/// Atempts to generate a validated receipt from the request and calls `onCompletion` when finished.
public final class LocalReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let request: ReceiptValidationRequest
    
    public var onCompletion: Completion?
    
    public init(request: ReceiptValidationRequest) {
        self.request = request
    }
    
    public func start() {
        DispatchQueue.global(qos: .background).async {
            do {
                let receipt = try self.receipt(from: self.request.data)
                
                self.onCompletion?(.succeeded(receipt))
            } catch let error {
                self.onCompletion?(.failed(error))
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
