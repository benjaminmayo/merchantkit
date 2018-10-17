/// A `Product` represents something that the user may have purchased.
public struct Product : Hashable, CustomStringConvertible {
    public let identifier: String
    public let kind: Kind
    
    public init(identifier: String, kind: Kind) {
        self.identifier = identifier
        self.kind = kind
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.identifier)'"))
    }
    
    public var hashValue: Int {
        return self.identifier.hashValue
    }
    
    public static func ==(lhs: Product, rhs: Product) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    /// Represents the possible In-App Purchases types.
    public enum Kind : Hashable {
        case consumable
        case nonConsumable
        case subscription(automaticallyRenews: Bool)
    }
}
