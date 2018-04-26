import XCTest
import Foundation

extension XCTest {
    func dataForSampleResource(withName name: String, `extension`: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        
        guard let url = bundle.url(forResource: name, withExtension: `extension`), let data = try? Data(contentsOf: url) else {
            print("resource '\(name).\(`extension`)' not found")
            return nil
        }

        return data
    }
}
