import Foundation

public final class UserDefaultsPurchaseStorage : PurchaseStorage {
    private let defaults = UserDefaults.standard
    
    public init() {
        
    }
    
    private let storageKeyPrefix: String = "purchaseStorage"
    
    public func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord? {
        let storageKey = self.storageKey(forProductIdentifier: productIdentifier)
        guard let dict = self.defaults.dictionary(forKey: storageKey) else { return nil }
        
        return PurchaseRecord(from: dict)
    }
    
    public func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult {
        let previousRecord = self.record(forProductIdentifier: record.productIdentifier)
        
        guard record != previousRecord else {
            return .noChanges
        }
        
        let key = self.storageKey(forProductIdentifier: record.productIdentifier)
        let dict = record.dictionaryRepresentation
        
        self.defaults.set(dict, forKey: key)
        
        return .didChangeRecords
    }
    
    public func removeRecord(forProductIdentifier productIdentifier: String) -> PurchaseStorageUpdateResult {
        let key = self.storageKey(forProductIdentifier: productIdentifier)
        
        self.defaults.removeObject(forKey: key)
        
        return .didChangeRecords
    }
    
    private func storageKey(forProductIdentifier productIdentifier: String) -> String {
        return self.storageKeyPrefix + "." + productIdentifier
    }
}
