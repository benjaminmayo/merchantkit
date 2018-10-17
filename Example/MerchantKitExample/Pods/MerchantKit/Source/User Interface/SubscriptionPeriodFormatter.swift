import Foundation

/// Formats `SubscriptionPeriod` values into user-facing strings. This can be used to present the duration of a subscription in the interface. It produces strings like `7 days` or `two weeks`.
/// This type is work in progress and API surface is volatile.
/// - Note: This formatter is currently localized into English, French and Spanish.
public final class SubscriptionPeriodFormatter {
    /// The style of formatting of the unit count. For example, the count could be spelled out in words ('seven days') or represented numerically ('7 days'). Defaults to `numeric`.
    public var unitCountStyle: UnitCountStyle = .numeric {
        didSet {
            guard self.unitCountStyle != oldValue else { return }
        
            self.didChangeUnitCountStyle()
        }
    }
    
    /// Controls whether the formatter is allowed to pluralize the description of the period. Pluralisation is not always desirable. For example, the phrase '7 day free trial' is generally preferred over the pluralised form, '7 days free trial', in English. Defaults to `true`.
    public var canPluralizeUnits: Bool = true
    
    /// Controls whether the formatter is allowed to convert units or strictly abide to the units given in the period to be formatted. For example, the formatter can convert '1 week' into '7 days' automatically. Defaults to `true`.
    public var canConvertUnits: Bool = true
    
    /// Controls how the words of the formatted string are capitalized. Select from 'lower case', 'Sentence case' or 'Start Case' modes. Numeric formats are naturally unaffected by capitalization.
    public var capitalizationMode: CapitalizationMode = .lowerCase
    
    /// The preferred locale to use when formatting.
    public var locale: Locale = .current {
        didSet {
            guard self.locale != oldValue else { return }
            
            self.unitCountFormatter.locale = self.locale
            self.localizedStringSource = LocalizedStringSource(for: self.locale)
        }
    }
    
    /// A mapping of a singular subscription period unit to a subscription period of smaller units. This mapping may be customizable in a future release.
    public private(set) var singleUnitPeriodConversions = [SubscriptionPeriod.Unit : SubscriptionPeriod]()

    private let unitCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = .current
        
        return formatter
    }()
    
    private var localizedStringSource: LocalizedStringSource
    
    public init() {
        self.singleUnitPeriodConversions = [.week : .days(7)]
        
        self.localizedStringSource = LocalizedStringSource(for: self.locale)
    }
    
    public func string(from period: SubscriptionPeriod) -> String {
        let convertedPeriod = self.convertedPeriod(from: period)
        
        let unitName: String
        
        if self.canPluralizeUnits {
            unitName = self.localizedStringSource.pluralizedName(for: convertedPeriod.unit, count: convertedPeriod.unitCount)
        } else {
            unitName = self.localizedStringSource.name(for: convertedPeriod.unit)
        }
        
        let formattedUnitCount = self.formattedUnitCount(from: convertedPeriod.unitCount)
        
        switch self.capitalizationMode {
            case .sentenceCase:
                let phrase = self.localizedStringSource.joinedPhrase(forUnitName: unitName, formattedUnitCount: formattedUnitCount)
            
                return phrase.sentenceCapitalized(with: self.locale)
            case .startCase:
                let phrase = self.localizedStringSource.joinedPhrase(forUnitName: unitName.capitalized(with: self.locale), formattedUnitCount: formattedUnitCount.capitalized(with: self.locale))
            
                return phrase
            case .lowerCase:
                let phrase = self.localizedStringSource.joinedPhrase(forUnitName: unitName, formattedUnitCount: formattedUnitCount)
                
                return phrase
        }
    }
    
    public enum UnitCountStyle {
        case numeric
        case spellOut
    }
    
    public enum CapitalizationMode {
        case sentenceCase
        case startCase
        case lowerCase
    }
}

extension SubscriptionPeriodFormatter {
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
    
    private func convertedPeriod(from period: SubscriptionPeriod) -> SubscriptionPeriod {
        guard self.canConvertUnits else { return period }
        
        if period.unitCount == 1 {
            if let converted = self.singleUnitPeriodConversions[period.unit] {
                return converted
            }
        }
        
        return period
    }
    
    private func formattedUnitCount(from unitCount: Int) -> String {
        let formattedString = self.unitCountFormatter.string(from: unitCount as NSNumber)!
        
        return formattedString
    }
}

