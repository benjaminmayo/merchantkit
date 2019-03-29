import XCTest
import Foundation
@testable import MerchantKit

class SubscriptionPeriodFormatterTests : XCTestCase {
    func testDefaultsInEnglish() {
        let expectations: [(SubscriptionPeriod, String)] = [
            (.days(7), "7 days"),
            (.days(14), "14 days"),
            (.weeks(1), "7 days"),
            (.weeks(14), "14 weeks"),
            (.months(1), "1 month"),
            (.months(14), "14 months"),
            (.years(1), "1 year"),
            (.years(14), "14 years")
        ]
        
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")

        for (period, result) in expectations {
            let formattedString = formatter.string(from: period)
        
            XCTAssertEqual(formattedString, result)
        }
    }
    
    func testSingularCountWithDefaultsInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        
        let formattedString = formatter.string(from: .days(1))
        
        XCTAssertEqual(formattedString, "1 day")
    }
    
    func testPluralizationDisabledInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.canPluralizeUnits = false
        
        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "7 day")
    }
    
    func testSpelloutSentenceCaseInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.unitCountStyle = .spellOut
        formatter.capitalizationMode = .sentenceCase

        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "Seven days")
    }
    
    func testSpelloutStartCaseInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.unitCountStyle = .spellOut
        formatter.capitalizationMode = .startCase
        
        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "Seven Days")
    }
    
    func testUnitConversionDisabledInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.canConvertUnits = false
        
        let formattedString = formatter.string(from: .weeks(1))
        XCTAssertEqual(formattedString, "1 week")
    }
    
    func testDefaultsWithInternationalization() {
        typealias Expectation = (testingLocale: Locale, result: String)
        
        let period: SubscriptionPeriod = .years(2)
        
        let englishExpectation = Expectation(Locale(identifier: "en"), "2 years")
        let frenchExpectation = Expectation(Locale(identifier: "fr-FR"), "2 ans")
        let spanishExpectation = Expectation(Locale(identifier: "es"), "2 años")
        
        let expectations = [englishExpectation, frenchExpectation, spanishExpectation]
        
        for expectation in expectations {
            let formatter = SubscriptionPeriodFormatter()
            formatter.locale = expectation.testingLocale
            
            let formattedString = formatter.string(from: period)
            XCTAssertEqual(formattedString, expectation.result)
        }
    }
    
    func testChangingUnitCountStyle() {
        let period: SubscriptionPeriod = .years(2)
        
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")
        
        formatter.unitCountStyle = .numeric
        XCTAssertEqual(formatter.string(from: period), "2 years")

        formatter.unitCountStyle = .spellOut
        XCTAssertEqual(formatter.string(from: period), "two years")
        
        formatter.unitCountStyle = .numeric
        XCTAssertEqual(formatter.string(from: period), "2 years")
    }

    func testUnsupportedLocale() {
        let period: SubscriptionPeriod = .years(2)
        
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "ja-JP")
        
        formatter.unitCountStyle = .numeric
        XCTAssertEqual(formatter.string(from: period), "2 years")
    }
}
