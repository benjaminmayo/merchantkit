#if canImport(openssl)
import openssl
#endif

/// This class is designed to abstract the underlying implementation details of a PKCS7 struct.
/// Using this class successfully currently requires `openssl` as a dependency. However, it will build even when this module is unavailable to allow other parts of the `MerchantKit` framework to be tested outside of app contexts.
/// In future, it would be nice to make this class more elegant, perhaps by removing the openssl dependency entirely.

internal final class PKCS7Container {
    #if canImport(openssl)
    private let wrappingPKCS7: PKCS7
    #endif
    
    init(from data: Data) throws {
        #if canImport(openssl)
            let bio = BIO_new(BIO_s_mem())!
        
            defer {
                BIO_free(bio)
            }
        
            self.wrappingPKCS7 = try data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> PKCS7 in
                let buffer = UnsafeRawPointer(bytes)
                
                BIO_write(bio, buffer, Int32(data.count))
                
                guard let container = d2i_PKCS7_bio(bio, nil) else {
                    throw Error.malformedInputData
                }
                
                return container.pointee
            })
        #else
            throw Error.missingOpenSSLDependency
        #endif
    }
    
    var content: Data? {
        #if canImport(openssl)
            guard let contents = self.wrappingPKCS7.d.sign.pointee.contents, let octets = contents.pointee.d.data?.pointee else {
                return nil
            }
        
            let pointer = UnsafeRawPointer(octets.data)!
        
            let data = Data(bytes: pointer, count: Int(octets.length))
        
            return data
        #else
            fatalError("Logic error, this class cannot be initialized without openSSL.")
        #endif
    }
    
    enum Error : Swift.Error {
        case missingOpenSSLDependency
        case malformedInputData
    }
}
