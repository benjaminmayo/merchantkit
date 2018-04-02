#if canImport(openssl)
import openssl
#endif

/// This class is designed to abstract the underlying implementation details of a PKCS7 struct.
/// Using this class successfully currently requires `openssl` as a dependency. However, it will build even when this module is unavailable to allow other parts of the `MerchantKit` framework to be tested outside of app contexts.
/// In future, it would be nice to make this class more elegant, perhaps by removing the openssl dependency entirely.

internal final class PKCS7Container {
    private let wrappingPKCS7: Any
    
    init(from data: Data) throws {
        #if canImport(openssl)
            let bio = BIO_new(BIO_s_mem())!
        
            defer {
                BIO_free(bio)
            }
        
            let pcks7 = data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> PKCS7? in
                let data = UnsafeRawPointer(bytes)
                
                BIO_write(bio, data, Int32(receiptData.count))
                
                guard let container = d2i_PKCS7_bio(bio, nil) else {
                    return nil
                }
                
                return container.pointee
            })
        
            if let result = pkcs7 {
                self.wrappingPKCS7 = result
            } else {
                return nil
            }
        #else
            throw Error.missingOpenSSLDependency
        #endif
    }
    
    var content: Data? {
        #if canImport(openssl)
            guard let contents = (self.wrappingPKCS7 as! PKCS7).d.sign.pointee.contents, let octets = contents.pointee.d.data?.pointee else {
                return nil
            }
        
            let pointer = UnsafeRawPointer(octets.data)!
        
            let data = Data(bytes: pointer, count: Int(octets.length))
        
            return data
        #endif
        
        fatalError("Logic error, this class cannot be initialized without openSSL.")
    }
    
    enum Error : Swift.Error {
        case missingOpenSSLDependency
        case malformedInputData
    }
}
