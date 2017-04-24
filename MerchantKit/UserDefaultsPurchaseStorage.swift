import Foundation

public final class UserDefaultsPurchaseStorage : PurchaseStorage {
    private let defaults = UserDefaults.standard
    
    public init() {
        
    }
    
    private let storageKeyPrefix: String = "productStore"
    
    internal func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord? {
        guard let dict = self.defaults.dictionary(forKey: productIdentifier) else { return nil }
        
        let record = self.record(from: dict)
        
        return record
    }
    
    internal func save(_ record: PurchaseRecord) -> SaveResult {
        let previousRecord = self.record(forProductIdentifier: record.productIdentifier)
        
        guard record != previousRecord else {
            return .noChanges
        }
        
        let key = self.storageKey(forProductIdentifier: record.productIdentifier)
        let dict = self.dict(for: record)
        
        self.defaults.set(dict, forKey: key)
        
        return .didChangeRecords
    }
    
    internal func removeRecord(forProductIdentifier productIdentifier: String) {
        let key = self.storageKey(forProductIdentifier: productIdentifier)
        
        self.defaults.removeObject(forKey: key)
    }
    
    private func storageKey(forProductIdentifier productIdentifier: String) -> String {
        return self.storageKeyPrefix + "." + productIdentifier
    }
    
    private func dict(for record: PurchaseRecord) -> [String : Any] {
        var dict: [String : Any] = [
            self.productIdentifierKey: record.productIdentifier,
            self.isPurchasedKey: NSNumber(value: record.isPurchased)
        ]
        
        if let expiryDate = record.expiryDate {
            dict[self.expiryDateKey] = expiryDate as NSDate
        }
        
        return dict
    }
    
    private func record(from dict: [String : Any]) -> PurchaseRecord {
        let productIdentifier = dict[self.productIdentifierKey] as! String
        let expiryDate = dict[self.expiryDateKey] as? NSDate
        let isPurchased = (dict[self.isPurchasedKey] as? NSNumber)?.boolValue ?? false
        
        return PurchaseRecord(productIdentifier: productIdentifier, expiryDate: expiryDate as Date?, isPurchased: isPurchased)
    }
    
    private let productIdentifierKey: String = "productIdentifier"
    private let expiryDateKey: String = "expiryDate"
    private let isPurchasedKey: String = "isPurchased"
}
