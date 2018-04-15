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
        let key: String
        
        switch unit {
            case .day:
                key = "Day"
            case .week:
                key = "Week"
            case .month:
                key = "Month"
            case .year:
                key = "Year"
        }
        
        let format = self._localizedString(key: key, fromTable: "LocalizedPeriodUnits")
        
        let result = String(format: format, locale: locale, arguments: [count])
        
        return result
    }
    
    func joinedPhrase(forUnitName unitName: String, formattedUnitCount unitCount: String) -> String {
        let format = self._localizedString(key: "UnitCountJoiner", fromTable: "LocalizedPeriodUnits")
        
        return String(format: format, arguments: [unitCount, unitName])
    }
}

extension LocalizedStringSource {
    private func _localizedString(key: String, fromTable tableName: String) -> String {
        return NSLocalizedString(key, tableName: tableName, bundle: Bundle(for: Merchant.self), value: "", comment: "")
    }
}
