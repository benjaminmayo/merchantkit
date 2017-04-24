import Foundation

public enum PurchasedState : Equatable {
    case unknown
    case notPurchased
    case isSubscribed(expiryDate: Date?)
    case isConsumable
    
    public var isPurchased: Bool {
        switch self {
            case .isSubscribed(_): return true
            case .isConsumable: return true
            case .notPurchased: return false
            case .unknown: return false
        }
    }
    
    public static func ==(lhs: PurchasedState, rhs: PurchasedState) -> Bool {
        switch (lhs, rhs) {
            case (.unknown, .unknown): return true
            case (.notPurchased, .notPurchased): return true
            case (.isSubscribed(let a), .isSubscribed(let b)): return a == b
            case (.isConsumable, .isConsumable): return true 
            default: return false
        }
    }
}
