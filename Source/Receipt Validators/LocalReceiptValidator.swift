import LibOpenSSL

/// Attempts to generate a validated receipt from the request and calls `onCompletion` when finished.
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
                let container = try self.pkcs7Container(from: self.request.data)
                
                let receipt = try self.receipt(from: container)
                
                self.onCompletion?(.succeeded(receipt))
            } catch let error {
                self.onCompletion?(.failed(error))
            }
        }
    }
    
    enum Error : Swift.Error {
        case missingContainer
        case malformedReceiptData
        case unexpectedReceiptASNObject
    }
}

extension LocalReceiptValidator {
    private func pkcs7Container(from receiptData: Data) throws -> PKCS7 {
        let bio = BIO_new(BIO_s_mem())!
        
        defer {
            BIO_free(bio)
        }
        
        return try receiptData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> PKCS7 in
            let data = UnsafeRawPointer(bytes)

            BIO_write(bio, data, Int32(receiptData.count))

            guard let container = d2i_PKCS7_bio(bio, nil) else {
                throw Error.missingContainer
            }
    
            return container.pointee
        })
    }
    
    private func receipt(from container: PKCS7) throws -> Receipt {
        guard let contents = container.d.sign.pointee.contents, let octets = contents.pointee.d.data?.pointee else {
            throw Error.malformedReceiptData
        }

        let parser = LocalReceiptPayloadParser()
        let pointer = UnsafeRawPointer(octets.data)!

        let data = Data(bytes: pointer, count: Int(octets.length))

        return try parser.receipt(from: data)
    }
}
