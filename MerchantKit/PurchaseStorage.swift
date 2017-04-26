public protocol PurchaseStorage : class {
    func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord?
    func save(_ record: PurchaseRecord) -> StorageUpdateResult
    func removeRecord(forProductIdentifier productIdentifier: String) -> StorageUpdateResult
}

public enum StorageUpdateResult {
    case didChangeRecords
    case noChanges
}
