import XCTest
@testable import MerchantKit

class SubscriptionPeriodFormatterTests: XCTestCase {
    func testDefaultsInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.locale = Locale(identifier: "en-US")

        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "7 days")
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
        formatter.unitCountStyle = .spellOut
        formatter.capitalizationMode = .sentenceCase
        formatter.locale = Locale(identifier: "en-US")
        
        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "Seven days")
    }
    
    func testSpelloutStartCaseInEnglish() {
        let formatter = SubscriptionPeriodFormatter()
        formatter.unitCountStyle = .spellOut
        formatter.capitalizationMode = .startCase
        formatter.locale = Locale(identifier: "en-US")
        
        let formattedString = formatter.string(from: .days(7))
        
        XCTAssertEqual(formattedString, "Seven Days")
    }
}
