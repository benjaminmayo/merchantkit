
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
    
    public enum Error : Swift.Error, CustomNSError {
        case requiresOpenSSL // you could argue that this condition should trap as it is a precondition, but — in this particular case — I prefer throwing an `Error` to enable better logging and debugging
        case missingContainer
        case malformedReceiptData
        case unexpectedReceiptASNObject
        
        public var errorCode: Int {
            switch self {
                case .requiresOpenSSL:
                    return 1
                case .missingContainer:
                    return 2
                case .malformedReceiptData:
                    return 3
                case .unexpectedReceiptASNObject:
                    return 4
            }
        }
        
        public var localizedDescription: String {
            switch self {
                case .requiresOpenSSL:
                    return "OpenSSL is required to use this MerchantKit feature."
                case .missingContainer:
                    return "The receipt container is missing."
                case .malformedReceiptData:
                    return "The receipt data is malformed."
                case .unexpectedReceiptASNObject:
                    return "The receipt data content contained an unrecognized object."
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
