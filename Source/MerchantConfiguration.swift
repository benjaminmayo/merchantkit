extension Merchant {
    public struct Configuration {
        public let receiptValidator: ReceiptValidator
        public let storage: PurchaseStorage
        
        public init(receiptValidator: ReceiptValidator, storage: PurchaseStorage) {
            self.receiptValidator = receiptValidator
            self.storage = storage
        }
    }
}

extension Merchant.Configuration {
    /// A standard configuration that will be applicable to most use cases. It validates receipts locally on device without requiring a network, and persists purchase data into the user's Keychain.
    public static var `default`: Merchant.Configuration {
        guard let serviceName = Bundle.main.bundleIdentifier, !serviceName.isEmpty else {
            MerchantKitFatalError.raise("Bundle.main.bundleIdentifier is used by `Merchant.Configuration.default`, but the string does not exist. You may want to supply your own `Merchant.Configuration`.")
        }
        
        let validator = LocalReceiptValidator()
        let storage = KeychainPurchaseStorage(serviceName: serviceName)
        
        return Merchant.Configuration(receiptValidator: validator, storage: storage)
    }
    
    /// As you can tell by the intentionally unwieldy name, this configuration is useful for testing but should not be used in shipping applications.
    /// You can use this configuration to easily test purchase flow. Even for non-consumable products, the Merchant will behave as if you are buying it for the first time. Repeat just by relaunching the application.
    public static var usefulForTestingAsPurchasedStateResetsOnApplicationLaunch: Merchant.Configuration {
        let validator = LocalReceiptValidator()
        let storage = EphemeralPurchaseStorage()
        
        return Merchant.Configuration(receiptValidator: validator, storage: storage)
    }
}
