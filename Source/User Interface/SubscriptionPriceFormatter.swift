import Foundation

/// Formats `Price` values into user-facing strings, incorporating the given `SubscriptionPeriod` into the phrase. This can be used to present the duration of a subscription in the interface. It produces strings like `7 days` or `two weeks`.
/// The formatter is aware of two generic `PhrasingStyle` options; `formal` ('£3.99 per month') and `informal` ('£3.99 a month'). If you want something more custom, consider composing a formatter out of `PriceFormatter` and `SubscriptionPeriodFormatter` objects.
/// This is typically used to display subscription products, but may have other use cases.
/// - Note: This formatter is currently localized into English only.
public final class SubscriptionPriceFormatter {
    /// The preferred phrasing style for the formatted string. If a phrasing style is unavailable for the given combination of price, duration and locale, the formatter will fall back to `formal`. Defaults to `formal`.
    public var phrasingStyle: PhrasingStyle = .formal
    
    /// The style of formatting of the provided subscription duration period's unit count. For example, the count could be spelled out in words ('seven days') or represented numerically ('7 days'). Defaults to `numeric`.
    public var unitCountStyle: UnitCountStyle = .numeric {
        didSet {
            guard self.unitCountStyle != oldValue else { return }
            
            self.didChangeUnitCountStyle()
        }
    }
    
    /// Replacement text if the price is free. If used by the formatter, the replacement text will be used instead of the normall formatted price. Defaults to empty string (which means it is ignored and a '0.00' numeric value will be used instead).
    public var freePriceReplacementText: String {
        get {
            return self.priceFormatter.freeReplacementText
        }
        
        set {
            self.priceFormatter.freeReplacementText = newValue
        }
    }
    
    /// The preferred locale to use when formatting.
    public var locale: Locale = .current {
        didSet {
            guard self.locale != oldValue else { return }
            
            self.unitCountFormatter.locale = self.locale
            self.localizedStringSource = LocalizedStringSource(for: self.locale)
        }
    }
    
    private let priceFormatter = PriceFormatter()
    private let unitCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = .current
        
        return formatter
    }()
    
    private var localizedStringSource: LocalizedStringSource
    
    public init() {
        self.localizedStringSource = LocalizedStringSource(for: self.locale)
    }
    
    public func string(from price: Price, duration: SubscriptionDuration) -> String {
        let formattedPrice = self.priceFormatter.string(from: price)
        let formattedUnitCount = self.formattedUnitCount(from: duration.period.unitCount)
        
        let configuration = LocalizedStringSource.SubscriptionPricePhraseConfiguration(
            duration: duration,
            isFormal: self.phrasingStyle == .formal
        )
        
        let phrase = self.localizedStringSource.subscriptionPricePhrase(with: configuration, formattedPrice: formattedPrice, formattedUnitCount: formattedUnitCount)
        
        return phrase
    }
    
    public enum PhrasingStyle {
        case informal
        case formal
    }
    
    public enum UnitCountStyle {
        case numeric
        case spellOut
    }
}

extension SubscriptionPriceFormatter {
    private func didChangeUnitCountStyle() {
        let numberStyle: NumberFormatter.Style
        
        switch self.unitCountStyle {
            case .numeric:
                numberStyle = .none
            case .spellOut:
                numberStyle = .spellOut
        }
        
        self.unitCountFormatter.numberStyle = numberStyle
    }
    
    private func formattedUnitCount(from unitCount: Int) -> String {
        let formattedString = self.unitCountFormatter.string(from: unitCount as NSNumber)!
        
        return formattedString
    }
}
