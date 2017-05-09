/// Not recommended for release builds. Useful for testing/debugging purposes. Does not persist any state between application launches.
public final class EphemeralPurchaseStorage : PurchaseStorage {
    private var records = [String : PurchaseRecord]()
    
    public init() {
        
    }
    
    public func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord? {
        return self.records[productIdentifier]
    }
    
    public func save(_ record: PurchaseRecord) -> StorageUpdateResult {
        let old = self.records[record.productIdentifier]
        
        if old != record {
            self.records[record.productIdentifier] = record
            
            return .didChangeRecords
        } else {
            return .noChanges
        }
    }
    
    public func removeRecord(forProductIdentifier productIdentifier: String) -> StorageUpdateResult {
        if let index = self.records.index(forKey: productIdentifier) {
            self.records.remove(at: index)
            
            return .didChangeRecords
        } else {
            return .noChanges
        }
    }
}
