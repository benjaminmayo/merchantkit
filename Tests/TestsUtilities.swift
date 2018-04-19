import XCTest
import Foundation

extension XCTest {
    func urlForSampleResource(withName name: String, `extension`: String) -> URL {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: name, withExtension: `extension`)!

        return url
    }
}
