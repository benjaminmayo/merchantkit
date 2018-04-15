import Foundation

internal struct LocalizedStringSource {
    let locale: Locale
    
    init(for locale: Locale) {
        self.locale = locale
    }
    
    func name(for unit: SubscriptionPeriod.Unit) -> String {
        return self.pluralizedName(for: unit, count: 1) // prolly a better way to do this
    }
    
    func pluralizedName(for unit: SubscriptionPeriod.Unit, count: Int) -> String {
        let identifier: Key.StringIdentifier
        
        switch unit {
            case .day:
                identifier = .day
            case .week:
                identifier = .week
            case .month:
                identifier = .month
            case .year:
                identifier = .year
        }
        
        let format = self.localizedString(for: .periodUnits(identifier))
        let result = String(format: format, locale: self.locale, arguments: [count])
        // uses magic to select an appropriate localized string for the given count argument, accounting for locale pluralisation rules
        
        return result
    }
    
    func joinedPhrase(forUnitName unitName: String, formattedUnitCount unitCount: String) -> String {
        let format = self.localizedString(for: .periodUnits(.unitCountJoiner))
        let result = String(format: format, locale: self.locale, arguments: [unitCount, unitName])
        
        return result
    }
}

extension LocalizedStringSource {
    private func localizedString(for key: Key) -> String {
        let mainBundle = Bundle(for: Merchant.self)
        
        // shockingly, this is the best way to specify a language for the localizedString(forKey:value:table:) Foundation API
        let bundleForLocalePath = self.locale.languageCode.flatMap { mainBundle.path(forResource: $0, ofType: "lproj") }
        
        let appropriateBundle: Bundle
        
        if let bundleForLocalePath = bundleForLocalePath, let bundleForLocale = Bundle(path: bundleForLocalePath) {
            appropriateBundle = bundleForLocale
        } else {
            appropriateBundle = mainBundle
        }
        
        // thanks to some Foundation framework magic, this returns a special kind of String. It is a dynamic subclass that can respond to String(format:locale:arguments:) by selecting the appropriate pluralisation as defined in the table.
        // if the 'string' is passed to other methods, it decays into a normal localized string lookup.
        return appropriateBundle.localizedString(forKey: key.stringValue, value: "", table: key.tableName)
    }
    
    private enum Key {
        case periodUnits(StringIdentifier)
        
        enum StringIdentifier : String {
            case unitCountJoiner = "UnitCountJoiner"
            
            case day = "Day"
            case week = "Week"
            case month = "Month"
            case year = "Year"
        }
        
        fileprivate var stringValue: String {
            switch self {
                case .periodUnits(let identifier):
                    return identifier.rawValue
            }
        }
        
        fileprivate var tableName: String {
            switch self {
                case .periodUnits(_):
                    return "LocalizedPeriodUnits"
            }
        }
    }
}
