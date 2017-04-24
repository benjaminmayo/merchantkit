import Foundation

public struct Price : Hashable, CustomStringConvertible {
    public let value: (NSDecimalNumber, Locale)
    
    internal init(from number: NSDecimalNumber, in locale: Locale) {
        self.value = (number, locale)
    }
    
    public var description: String {
        let formatter = Price._descriptionFormatter
        formatter.locale = self.value.1
        
        return self.defaultDescription(withProperties: ("", formatter.string(from: self.value.0)!))
    }
    
    public var hashValue: Int {
        return self.value.0.hashValue
    }
    
    public static func ==(lhs: Price, rhs: Price) -> Bool {
        return lhs.value == rhs.value
    }
    
    private static var _descriptionFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        return formatter
    }()
}
