import XCTest
import Foundation
@testable import MerchantKit

class LocalizedResourcesTests : XCTestCase {
    func testLocalizedPeriodUnitDayNameInEnglish() {
        let locale = Locale(identifier: "en-US")
        
        let source = LocalizedStringSource(for: locale)
        
        let localizedDayName = source.name(for: .day)
        XCTAssertEqual(localizedDayName, "day")
        
        let localizedPluralizedDayName = source.pluralizedName(for: .day, count: 2)
        XCTAssertEqual(localizedPluralizedDayName, "days")
    }
}
