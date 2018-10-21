/// A `Product` represents something that the user may have purchased.
public struct Product : Hashable, CustomStringConvertible {
    public let identifier: String
    public let kind: Kind
    
    /// Create a product with the unique product `identifier` and `kind` of In-App Purchase it represents.
    public init(identifier: String, kind: Kind) {
        self.identifier = identifier
        self.kind = kind
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.identifier)'"))
    }
    
    /// Represents the possible In-App Purchases types.
    public enum Kind : Hashable {
        case consumable
        case nonConsumable
        case subscription(automaticallyRenews: Bool)
    }
}
