import XCTest
import Foundation
@testable import MerchantKit

class SubscriptionPriceFormatterTests : XCTestCase {
    func testDefaultsInEnglish() {
        let expectations: [(SubscriptionDuration, String)] = [
            (.init(period: .days(7), isRecurring: true), "$5.99 every 7 days"),
            (.init(period: .days(14), isRecurring: false), "$5.99 for 14 days"),
            (.init(period: .weeks(1), isRecurring: true), "$5.99 per week"),
            (.init(period: .weeks(14), isRecurring: false), "$5.99 for 14 weeks"),
            (.init(period: .months(1), isRecurring: true), "$5.99 per month"),
            (.init(period: .months(14), isRecurring: false), "$5.99 for 14 months"),
            (.init(period: .years(1), isRecurring: true), "$5.99 per year"),
            (.init(period: .years(14), isRecurring: false), "$5.99 for 14 years")
        ]
        
        let locale = Locale(identifier: "en-US")
        
        let formatter = SubscriptionPriceFormatter()
        formatter.locale = locale
        
        let price = Price(value: (Decimal(string: "5.99")!, locale))

        for (duration, result) in expectations {
            let formattedString = formatter.string(from: price, duration: duration)
            
            XCTAssertEqual(formattedString, result)
        }
    }
    
    private func englishResult(forPrice priceString: String, duration: SubscriptionDuration, phrasingStyle: SubscriptionPriceFormatter.PhrasingStyle) -> String {
        let locale = Locale(identifier: "en-US")
        let price = Price(value: (Decimal(string: priceString)!, locale))
        
        let formatter = SubscriptionPriceFormatter()
        formatter.locale = locale
        formatter.phrasingStyle = phrasingStyle
        
        let result = formatter.string(from: price, duration: duration)
        
        return result
    }
    
    func test1DayInformalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(1), isRecurring: false), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 for 1 day")
    }
    
    func test1DayFormalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(1), isRecurring: false), phrasingStyle: .formal)

        XCTAssertEqual(result, "$1.99 for 1 day")
    }
    
    func test1DayInformalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(1), isRecurring: true), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 a day")
    }
    
    func test1DayFormalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(1), isRecurring: true), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 per day")
    }
    
    func test7DayInformalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(7), isRecurring: false), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 for 7 days")
    }
    
    func test7DayFormalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(7), isRecurring: false), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 for 7 days")
    }
    
    func test7DayInformalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(7), isRecurring: true), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 every 7 days")
    }
    
    func test7DayFormalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .days(7), isRecurring: true), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 every 7 days")
    }
    
    func test1MonthInformalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(1), isRecurring: false), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 for 1 month")
    }
    
    func test1MonthFormalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(1), isRecurring: false), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 for 1 month")
    }
    
    func test1MonthInformalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(1), isRecurring: true), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 a month")
    }
    
    func test1MonthFormalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(1), isRecurring: true), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 per month")
    }
    
    func test6MonthInformalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(6), isRecurring: false), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 for 6 months")
    }
    
    func test6MonthFormalFixedDurationInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(6), isRecurring: false), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 for 6 months")
    }
    
    func test6MonthInformalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(6), isRecurring: true), phrasingStyle: .informal)
        
        XCTAssertEqual(result, "$1.99 every 6 months")
    }
    
    func test6MonthFormalInEnglish() {
        let result = self.englishResult(forPrice: "1.99", duration: .init(period: .months(6), isRecurring: true), phrasingStyle: .formal)
        
        XCTAssertEqual(result, "$1.99 every 6 months")
    }
    
    func test6MonthFormalInEnglishSpellOut() {
        let locale = Locale(identifier: "en-US")
        let price = Price(value: (Decimal(string: "1.99")!, locale))
        
        let formatter = SubscriptionPriceFormatter()
        formatter.locale = locale
        formatter.phrasingStyle = .formal
        formatter.unitCountStyle = .spellOut
        
        let result = formatter.string(from: price, duration: .init(period: .months(6), isRecurring: true))
        
        XCTAssertEqual(result, "$1.99 every six months")
    }
    
    func testChangingUnitCountStyle() {
        let locale = Locale(identifier: "en-GB")

        let duration: SubscriptionDuration = .init(period: .years(2), isRecurring: true)
        let price = Price(value: (Decimal(string: "9.99")!, locale))

        let formatter = SubscriptionPriceFormatter()
        formatter.locale = locale
        
        formatter.unitCountStyle = .numeric
        XCTAssertEqual(formatter.string(from: price, duration: duration), "£9.99 every 2 years")
        
        formatter.unitCountStyle = .spellOut
        XCTAssertEqual(formatter.string(from: price, duration: duration), "£9.99 every two years")
        
        formatter.unitCountStyle = .numeric
        XCTAssertEqual(formatter.string(from: price, duration: duration), "£9.99 every 2 years")
    }
    
    func testFreeReplacementText() {
        let locale = Locale(identifier: "en-GB")
        
        let duration: SubscriptionDuration = .init(period: .years(1), isRecurring: false)
        let price = Price(value: (Decimal(string: "0.00")!, locale))

        let formatter = SubscriptionPriceFormatter()
        formatter.locale = locale
        formatter.unitCountStyle = .numeric
        formatter.freePriceReplacementText = "FREE"
        
        // formatter remembered the replacement text
        XCTAssertEqual(formatter.freePriceReplacementText, "FREE")
        
        let result = formatter.string(from: price, duration: duration)
        XCTAssertEqual(result, "FREE for 1 year")
    }
}
