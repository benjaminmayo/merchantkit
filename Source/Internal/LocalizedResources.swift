import Foundation

internal class LocalizedStringSource {
    private var provider: LocalizedStringProvider!
    
    private var _cachedResourceDicts = [String : [String : Any]]()
    
    init(for locale: Locale) {
        self.provider = FoundationLocalizedStringProvider(locale: locale, bundle: self.bundle(for: locale))
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
        
        return self.provider.localizedString(for: .periodUnits(identifier), formatting: [count])
    }
    
    func joinedPhrase(forUnitName unitName: String, formattedUnitCount unitCount: String) -> String {
        return self.provider.localizedString(for: .periodUnits(.unitCountJoiner), formatting: [unitCount, unitName])
    }
    
    func subscriptionPricePhrase(with configuration: SubscriptionPricePhraseConfiguration, formattedPrice: String, formattedUnitCount: String) -> String {
        return self.provider.localizedString(for: .subscriptionPricePhrases(configuration), formatting: [configuration.duration.period.unitCount, formattedPrice, formattedUnitCount])
    }
    
    internal struct SubscriptionPricePhraseConfiguration {
        let duration: SubscriptionDuration
        let isFormal: Bool
    }
}

extension LocalizedStringSource {
    private func bundle(for locale: Locale) -> Bundle {
        let frameworkBundle = Bundle(for: Merchant.self)
        
        // shockingly, this is the best way to specify a language for the localizedString(forKey:value:table:) Foundation API
        let bundleForLocalePath = locale.languageCode.flatMap { frameworkBundle.path(forResource: $0, ofType: "lproj") }
        
        let appropriateBundle: Bundle
        
        if let bundleForLocalePath = bundleForLocalePath, let bundleForLocale = Bundle(path: bundleForLocalePath) {
            appropriateBundle = bundleForLocale
        } else {
            appropriateBundle = frameworkBundle
        }
        
        return appropriateBundle
    }
    
    fileprivate enum Key {
        case periodUnits(StringIdentifier)
        case subscriptionPricePhrases(SubscriptionPricePhraseConfiguration)
        
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
                case .subscriptionPricePhrases(let configuration):
                    let unitIdentifier: String
                    
                    switch configuration.duration.period.unit {
                        case .day: unitIdentifier = "Day"
                        case .week: unitIdentifier = "Week"
                        case .month: unitIdentifier = "Month"
                        case .year: unitIdentifier = "Year"
                    }
                    
                    let formalIdentifier = configuration.isFormal ? "Formal" : "Informal"
                    let fixedDurationIdentifier = configuration.duration.isRecurring ? "NotFixedDuration" : "FixedDuration"
                    
                    let value = "\(unitIdentifier)\(formalIdentifier)\(fixedDurationIdentifier)"
                
                    return value
            }
        }
        
        fileprivate var tableName: String {
            switch self {
                case .periodUnits(_):
                    return "LocalizedPeriodUnits"
                case .subscriptionPricePhrases(_):
                    return "LocalizedSubscriptionPricePhrases"
            }
        }
    }
}

fileprivate protocol LocalizedStringProvider {
    init(locale: Locale, bundle: Bundle)
    
    func localizedString(for key: LocalizedStringSource.Key, formatting arguments: [CVarArg]) -> String
}

/// This handles the replacement logic that Foundation does 'magically'. The downside to this approach is that MerchantKit becomes responsible for handling pluralization rules. This kinda sucks but maybe needed in the future if the Foundation approach becomes untenable.
//fileprivate final class InternalLocalizedStringProvider : LocalizedStringProvider {
//    private let locale: Locale
//    private let bundle: Bundle
//
//    private var _cachedResourceDicts = [String : [String : Any]]()
//
//    init(locale: Locale, bundle: Bundle) {
//        self.locale = locale
//        self.bundle = bundle
//    }
//
//    func localizedString(for key: LocalizedStringSource.Key, formatting arguments: [CVarArg]) -> String {
//        enum FormattedLocalizedStringError : Swift.Error {
//            case urlNotFound(resourceName: String)
//            case plistWrongFormat
//            case missingValue(key: String)
//            case unexpectedValue(key: String)
//        }
//
//        do {
//            let resourceName = "MerchantKitResources\(key.tableName)"
//
//            let dict: [String : Any]
//
//            if let cached = self._cachedResourceDicts[resourceName] {
//                dict = cached
//            } else {
//                guard let url = self.bundle.url(forResource: resourceName, withExtension: "stringsdict", subdirectory: "") else { throw FormattedLocalizedStringError.urlNotFound(resourceName: resourceName) }
//
//                let data = try Data(contentsOf: url)
//                guard let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any] else {
//                    throw FormattedLocalizedStringError.plistWrongFormat
//                }
//
//                dict = decoded
//            }
//
//            guard let formatContainer = dict[key.stringValue] as? [String : Any] else {
//                throw FormattedLocalizedStringError.unexpectedValue(key: key.stringValue)
//            }
//
//            let localizedFormatKey = "NSStringLocalizedFormatKey"
//
//            guard let rawFormat = formatContainer[localizedFormatKey] as? String else {
//                throw FormattedLocalizedStringError.unexpectedValue(key: localizedFormatKey)
//            }
//
//            var replacementData = [(key: String, replacement: String)]()
//
//            if formatContainer.count > 1 {
//                let pluralizations = self.acceptablePluralizations(for: arguments.first as! Int)
//
//                for (replacementKey, object) in formatContainer {
//                    guard replacementKey != localizedFormatKey else { continue }
//
//                    if let object = object as? [String : String] {
//                        guard let stringValue = self.stringValue(forPluralizationsList: object, selectingFrom: pluralizations) else {
//                            throw FormattedLocalizedStringError.missingValue(key: replacementKey)
//                        }
//
//                        replacementData.append((replacementKey, stringValue))
//                    }
//                }
//            }
//
//            var replacedFormat = rawFormat
//
//            for (key, replacement) in replacementData {
//                replacedFormat = replacedFormat.replacingOccurrences(of: "%#@\(key)@", with: replacement)
//            }
//
//            for (index, argument) in arguments.enumerated() {
//                replacedFormat = replacedFormat.replacingOccurrences(of: "%\(index + 1)$@", with: String(describing: argument as Any))
//            }
//
//            let format = replacedFormat
//            let result = String(format: format, arguments: arguments)
//
//            return result
//        } catch let error {
//            print(error)
//
//            return "Unhandled+\(key.stringValue)"
//        }
//    }
//
//    private func acceptablePluralizations(for count: Int) -> [Pluralization] {
//        // this will need to be expanded to support more locales eventually
//
//        switch count {
//            case 1:
//                return [.one, .other]
//            default:
//                return [.other]
//        }
//    }
//
//    private func stringValue(forPluralizationsList object: [String : String], selectingFrom acceptablePluralizations: [Pluralization]) -> String? {
//        for pluralization in acceptablePluralizations {
//            if let value = object[pluralization.rawValue] {
//                return value
//            }
//        }
//
//        return nil
//    }
//
//    private enum Pluralization : String {
//        case zero
//        case one
//        case two
//        case few
//        case many
//        case other
//    }
//}

/// This handles localized string replacement. Unfortunately, it is kind of a black box and sometimes unreliable. For now, we include this implementation as a backup — with a view to select a single concrete provider down the road.
fileprivate final class FoundationLocalizedStringProvider : LocalizedStringProvider {
    private let locale: Locale
    private let bundle: Bundle

    init(locale: Locale, bundle: Bundle) {
        self.locale = locale
        self.bundle = bundle
    }

    func localizedString(for key: LocalizedStringSource.Key, formatting arguments: [CVarArg]) -> String {
        let format = self.bundle.localizedString(forKey: key.stringValue, value: "", table: "MerchantKitResources\(key.tableName)")

        let result = String(format: format, locale: self.locale, arguments: arguments)
        
        return result
    }
}
