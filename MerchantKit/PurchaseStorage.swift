public protocol PurchaseStorage {
    func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord?
    func save(_ record: PurchaseRecord)
    func removeRecord(forProductIdentifier productIdentifier: String)
}
