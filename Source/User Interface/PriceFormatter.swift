import Foundation

/// Formats `Price` values into user-facing strings. This can be used to display the cost of a `Purchase` to end users. It produces strings like `£3.99` or `$9.99`. 
///
/// Typically, you will pass a `Purchase.price` to this formatter for display in the user interface. Use `SubscriptionPriceFormatter` for subscription products where strings like `£3.99 per month` are more appropriate.
/// - Note: This formatter is currently localized into English, French and Spanish.
public final class PriceFormatter {
    /// Text to prepend before the formatted price value. Defaults to empty string.
    public var prefix: String = ""
    /// Text to append after the formatted price value. Defaults to empty string.
    public var suffix: String = ""
    /// Replacement text if the price is free. If used by the formatter, `prefix` and `suffix` are ignored. Defaults to empty string.
    public var freeText: String = ""
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    private static let zero = NSDecimalNumber(value: 0.0)
    
    public init() {
        
    }
    
    public func string(from price: Price) -> String {
        let (number, _) = price.value

        let isFree = number.compare(PriceFormatter.zero) != .orderedDescending
        
        if isFree && !self.freeText.isEmpty {
            return self.freeText
        }
        
        let numberFragment = self.formattedNumerals(from: price)
        
        let components = [self.prefix, numberFragment, self.suffix]
        
        return components.joined(separator: "")
    }
    
    private func formattedNumerals(from price: Price) -> String {
        let (number, locale) = price.value

        self.numberFormatter.locale = locale
        
        return self.numberFormatter.string(from: number)!
    }
}
