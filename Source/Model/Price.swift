/// The `Price` encapsulates a numeric value and locale. Use a `PriceFormatter` to display the purchase price of a product in UI.
public struct Price : Hashable, CustomStringConvertible {
    /// Underlying values that make up the `Price`
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
