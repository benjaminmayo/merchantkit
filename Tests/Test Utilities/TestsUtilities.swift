import XCTest
import Foundation

extension XCTest {
    func dataForSampleResource(withName name: String, `extension`: String) -> Data? {
        let bundle = self.bundleForTestResources
        
        guard let url = bundle.url(forResource: name, withExtension: `extension`), let data = try? Data(contentsOf: url) else {
            print("resource '\(name).\(`extension`)' not found")
            return nil
        }

        return data
    }
    
    private var bundleForTestResources: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: type(of: self))
        #endif
    }
}
