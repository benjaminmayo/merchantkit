import Foundation

/// Formats `SubscriptionPeriod` values into user-facing strings. This can be used to present the duration of a subscription in the interface. It produces strings like `7 days` or `two weeks`.
/// This type is work in progress and API surface is volatile. Eventually, it should support non-English languages.
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
    
    /// The locale to use when formatting. `SubscriptionPeriodFormatter` currently assumes an English language.
    public var locale: Locale = .current {
        didSet {
            self.unitCountFormatter.locale = self.locale
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
    
    public init() {
        self.singleUnitPeriodConversions = [.week : .days(7)]
    }
    
    public func string(from period: SubscriptionPeriod) -> String {
        let convertedPeriod = self.convertedPeriod(from: period)
        
        let pluralizationMode = self.pluralizationMode(fromUnitCount: convertedPeriod.unitCount)
        let formattedUnitCount = self.formattedString(fromUnitCount: convertedPeriod.unitCount)
        
        let formattedUnit = self.formattedString(from: convertedPeriod.unit, pluralizationMode: pluralizationMode)
        
        switch self.capitalizationMode {
            case .sentenceCase:
                return "\(formattedUnitCount.capitalized(with: self.locale)) \(formattedUnit)"
            case .startCase:
                return "\(formattedUnitCount.capitalized(with: self.locale)) \(formattedUnit.capitalized(with: self.locale))"
            case .lowerCase:
                return "\(formattedUnitCount) \(formattedUnit)"
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
    
    private func formattedString(fromUnitCount unitCount: Int) -> String {
        let formattedString = self.unitCountFormatter.string(from: unitCount as NSNumber)!
        
        return formattedString
    }
    
    // this is rudimentary
    private func formattedString(from unit: SubscriptionPeriod.Unit, pluralizationMode: PluralizationMode) -> String {
        switch (unit, pluralizationMode) {
            case (.day, .singular):
                return "day"
            case (.day, .plural(_)):
                return "days"
            case (.week, .singular):
                return "week"
            case (.week, .plural(_)):
                return "weeks"
            case (.month, .singular):
                return "month"
            case (.month, .plural(_)):
                return "months"
            case (.year, .singular):
                return "year"
            case (.year, .plural(_)):
                return "years"
        }
    }
    
    private func pluralizationMode(fromUnitCount unitCount: Int) -> PluralizationMode {
        guard self.canPluralizeUnits else { return .singular }
        
        switch unitCount {
            case 1:
                return .singular
            default:
                return .plural(.other)
        }
    }
    
    private enum PluralizationMode {
        case singular
        case plural(PluralModifier)
        
        enum PluralModifier {
            case other
            case few
            case many
        }
    }
}
