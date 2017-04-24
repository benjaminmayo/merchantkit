import Foundation
import StoreKit

public protocol MerchantDelegate : class {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    func merchant(_ merchant: Merchant, validate receipt: Receipt, completion: @escaping (_ isValid: Bool) -> Void)
}

public final class Merchant {
    public let delegate: MerchantDelegate
    
    fileprivate let storage: PurchaseStorage
    private let transactionObserver = StoreKitTransactionObserver()
    
    fileprivate var registeredProducts = [String : Product]()
    
    public init(delegate: MerchantDelegate) {
        self.delegate = delegate
        self.storage = UserDefaultsPurchaseStorage()
    }
    
    public func beginObservingTransactions() {
        self.transactionObserver.delegate = self
        
        SKPaymentQueue.default().add(self.transactionObserver)
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

extension Merchant {
    fileprivate func didChangeState(for products: Set<Product>) {
        self.delegate.merchant(self, didChangeStatesFor: products)
    }
}

extension Merchant : StoreKitTransactionObserverDelegate {
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didPurchaseProductWith identifier: String) {
        guard let product = self.registeredProducts[identifier] else { print("unrecognized product identifier"); return } // TODO: Consider error handling
        
        guard product.kind == .nonConsumable else { print(product.kind, "not supported via storekit observation"); return } // TODO: Implement consumable support, Decide correct flow for subscription products
        
        let record = PurchaseRecord(productIdentifier: identifier, expiryDate: nil, isPurchased: true)
        let result = self.storage.save(record)
        
        if result == .didChangeRecords {
            self.didChangeState(for: [product])
        }
    }
}
