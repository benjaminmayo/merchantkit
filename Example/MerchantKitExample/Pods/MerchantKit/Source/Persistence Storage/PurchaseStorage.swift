public protocol PurchaseStorage : AnyObject {
    func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord?
    func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult
    func removeRecord(forProductIdentifier productIdentifier: String) -> PurchaseStorageUpdateResult
}

public enum PurchaseStorageUpdateResult {
    case didChangeRecords
    case noChanges
}
