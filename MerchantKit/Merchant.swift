import Foundation
import StoreKit

public protocol MerchantDelegate : class {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    func merchant(_ merchant: Merchant, validate receipt: Receipt, completion: @escaping (_ isValid: Bool) -> Void)
}

public final class Merchant {
    public let delegate: MerchantDelegate
    
    private let storage: PurchaseStorage
    
    private var registeredProducts = [String : Product]()
    
    public init(delegate: MerchantDelegate) {
        self.delegate = delegate
        self.storage = UserDefaultsPurchaseStorage()
    }
    
    public func register<Products : Sequence>(_ products: Products) where Products.Iterator.Element == Product {
        for product in products {
            self.registeredProducts[product.identifier] = product
        }
    }
    
    public func state(forProductWithIdentifier productIdentifier: String) -> PurchasedState {
        guard let product = self.registeredProducts[productIdentifier] else {
            return .unknown
        }
        
        guard let record = self.storage.record(forProductIdentifier: productIdentifier) else {
            return .unknown
        }
        
        switch product.kind {
            case .consumable:
                fatalError("consumable support not yet implemented")
            case .nonConsumable:
                if record.isPurchased {
                    return .isConsumable
                } else {
                    return .notPurchased
                }
            case .subscription(_):
                let now = Date()
                
                if let expiryDate = record.expiryDate, expiryDate > now {
                    return .isSubscribed(expiryDate: expiryDate)
                } else if record.isPurchased {
                    return .isSubscribed(expiryDate: nil)
                } else {
                    return .notPurchased
                }
        }
    }
}

private class StoreKitTransactionObserver : NSObject, SKPaymentTransactionObserver {
    private override init() {
        super.init()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchased:
                    self.completePurchase(for: transaction)
                case .purchasing:
                    break
                case .restored:
                    self.completePurchase(for: transaction.original!)
                case .failed:
                    break
                case .deferred:
                    break
            }
        }
    }
    
    private func completePurchase(for transaction: SKPaymentTransaction) {
        
    }
}
