
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
    
    public enum Error : Swift.Error {
        case requiresOpenSSL // you could argue that this condition should trap as it is a precondition, but — in this particular case — I prefer throwing an `Error` to enable better logging and debugging
        case missingContainer
        case malformedReceiptData
        case unexpectedReceiptASNObject
    }
}

extension LocalReceiptValidator {
    private func receipt(from receiptData: Data) throws -> Receipt {
        do {
            let container = try PKCS7Container(from: receiptData)
            
            guard let content = container.content else { throw Error.malformedReceiptData }
            
            let parser = LocalReceiptPayloadParser()
            
            return try parser.receipt(from: content)
        } catch PKCS7Container.Error.missingOpenSSLDependency {
            throw Error.requiresOpenSSL
        } catch PKCS7Container.Error.malformedInputData {
            throw Error.missingContainer
        } catch is ASN1Format.ParseError {
            throw Error.unexpectedReceiptASNObject
        }
    }
}
