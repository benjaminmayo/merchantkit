import Foundation

extension Date {
    internal init(millisecondsSince1970 milliseconds: Int) {
        self.init(timeIntervalSince1970: Double(milliseconds / 1000))
    }
}
