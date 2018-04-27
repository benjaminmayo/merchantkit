/// Not recommended for release builds. Useful for testing/debugging purposes. Does not persist any state between application launches.
public final class EphemeralPurchaseStorage : PurchaseStorage {
    private var records = [String : PurchaseRecord]()
    
    public init() {
        
    }
    
    public func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord? {
        return self.records[productIdentifier]
    }
    
    public func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult {
        let old = self.records[record.productIdentifier]
        
        guard old != record else {
            return .noChanges
        }
        
        self.records[record.productIdentifier] = record
            
        return .didChangeRecords
    }
    
    public func removeRecord(forProductIdentifier productIdentifier: String) -> PurchaseStorageUpdateResult {
        guard let index = self.records.index(forKey: productIdentifier) else {
            return .noChanges
        }
        
        self.records.remove(at: index)
            
        return .didChangeRecords
    }
}
