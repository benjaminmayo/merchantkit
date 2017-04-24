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
        return lhs.identifier == rhs.identifier && lhs.hashValue == rhs.hashValue
    }
    
    public enum Kind : Equatable {
        case consumable
        case nonConsumable
        case subscription(automaticallyRenews: Bool)
        
        public static func ==(lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
                case (.consumable, .consumable): return true
                case (.nonConsumable, .nonConsumable): return true
                case (.subscription(let a), .subscription(let b)): return a == b
                default: return false
            }
        }
    }
}
