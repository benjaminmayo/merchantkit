/// Formats `Price` values into user-facing strings, incorporating the given `SubscriptionPeriod` into the phrase. This can be used to present the duration of a subscription in the interface. It produces strings like `7 days` or `two weeks`.

internal final class SubscriptionPriceFormatter {
    public var isSubscriptionFixedDuration: Bool = false
    public var phrasingStyle: PhrasingStyle = .informal
    
    /// The style of formatting of the unit count. For example, the count could be spelled out in words ('seven days') or represented numerically ('7 days'). Defaults to `numeric`.
    public var unitCountStyle: UnitCountStyle = .numeric {
        didSet {
            guard self.unitCountStyle != oldValue else { return }
            
            self.didChangeUnitCountStyle()
        }
    }
    
    public var locale: Locale = .current {
        didSet {
            self.unitCountFormatter.locale = self.locale
        }
    }
    
    private let priceFormatter = PriceFormatter()
    private let unitCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = .current
        
        return formatter
    }()
    
    init() {
        
    }
    
    func string(from price: Price, period: SubscriptionPeriod) -> String {
        let formattedPrice = self.priceFormatter.string(from: price)
        let formattedUnitCount = self.formattedUnitCount(from: period.unitCount)
        
        let localizedStringSource = LocalizedStringSource(for: self.locale)
        
        let configuration = LocalizedStringSource.SubscriptionPricePhraseConfiguration(
            period: period,
            isFormal: self.phrasingStyle == .formal,
            isFixedDuration: self.isSubscriptionFixedDuration
        )
        
        let phrase = localizedStringSource.subscriptionPricePhrase(with: configuration, formattedPrice: formattedPrice, formattedUnitCount: formattedUnitCount)
        return phrase
        
        //                  |Informal                 |Formal                |
        
        // * Price: £3.99, Period: 1 month *
        // |isFixedPeriod   |£3.99 for 1 month        |£3.99 for 1 month     |
        // |isNotFixedPeriod|£3.99 a month            |£3.99 per month       |
        
        // * Price: £4.99, Period: 3 months *
        // |isFixedPeriod   |£3.99 for 3 months       |£3.99 for 3 months    |
        // |isNotFixedPeriod|£3.99 every 3 months     |£3.99 every 3 months  |
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
