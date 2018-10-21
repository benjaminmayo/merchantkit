import Foundation

/// Formats `Price` values into user-facing strings. This can be used to display the cost of a `Purchase` to end users. It produces strings like `£3.99` or `$9.99`. 
///
/// Typically, you will pass a `Purchase.price` to this formatter for display in the user interface. Use `SubscriptionPriceFormatter` for subscription products where strings like `£3.99 per month` are more appropriate.
public final class PriceFormatter {
    /// Text to prepend before the formatted price value. Defaults to empty string.
    public var prefix: String = ""
    
    /// Text to append after the formatted price value. Defaults to empty string.
    public var suffix: String = ""
    
    /// Replacement text if the price is free. If used by the formatter, `prefix` and `suffix` are ignored. Defaults to empty string (which means it is ignored and a '0.00' numeric value will be used instead).
    public var freeReplacementText: String = ""
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    private static let zero: Decimal = 0.0
    
    public init() {
        
    }
    
    public func string(from price: Price) -> String {
        let formattedPrice = self.formattedPrice(from: price)
        
        return formattedPrice
    }
}

extension PriceFormatter {
    private func formattedPrice(from price: Price) -> String {
        let (number, locale) = price.value
        
        let isFree = number <= PriceFormatter.zero
        
        if isFree && !self.freeReplacementText.isEmpty {
            return self.freeReplacementText
        }
        
        self.numberFormatter.locale = locale
        let numberFragment = self.numberFormatter.string(from: number as NSDecimalNumber)!
        
        let components = [self.prefix, numberFragment, self.suffix]
        
        return components.joined(separator: "")
    }
}
