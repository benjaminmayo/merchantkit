import Foundation

extension Bundle {
    // the resource bundle that conditionally compiles for SwiftPM and other build methods
    static var forMerchantKitResources: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Merchant.self)
        #endif
    }
}
