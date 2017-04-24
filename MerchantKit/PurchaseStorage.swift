internal protocol PurchaseStorage : class {
    func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord?
    func save(_ record: PurchaseRecord) -> SaveResult
    func removeRecord(forProductIdentifier productIdentifier: String)
}

internal enum SaveResult {
    case didChangeRecords
    case noChanges
}
