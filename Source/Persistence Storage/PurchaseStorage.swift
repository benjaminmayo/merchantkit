public protocol PurchaseStorage : AnyObject {
    func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord?
    func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult
    func removeRecord(forProductIdentifier productIdentifier: String) -> PurchaseStorageUpdateResult
    func state(for product: Product) -> PurchasedState
}

public extension PurchaseStorage {
  /// Returns the state for a `product`. Consumable products always report that they are `notPurchased`.
  public func state(for product: Product) -> PurchasedState {
    guard let record = record(forProductIdentifier: product.identifier) else { return .notPurchased }

    switch product.kind {
    case .consumable:
      return .notPurchased
    case .nonConsumable, .subscription(automaticallyRenews: _):
      let info = PurchasedProductInfo(expiryDate: record.expiryDate)
      return .isPurchased(info)
    }
  }
}

public enum PurchaseStorageUpdateResult {
    case didChangeRecords
    case noChanges
}
