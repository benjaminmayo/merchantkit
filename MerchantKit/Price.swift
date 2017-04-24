import Foundation

public struct Price : Hashable {
    public let value: (NSDecimalNumber, Locale)
    
    internal init(from number: NSDecimalNumber, in locale: Locale) {
        self.value = (number, locale)
    }
    
    public var hashValue: Int {
        return self.value.0.hashValue
    }
    
    public static func ==(lhs: Price, rhs: Price) -> Bool {
        return lhs.value == rhs.value 
    }
}
