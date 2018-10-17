import Foundation

extension Date {
    internal init(millisecondsSince1970 milliseconds: Int) {
        self.init(timeIntervalSince1970: Double(milliseconds / 1000))
    }
    
    internal init?(fromISO8601 string: String) {
        if let date = Date.iso8601Formatter.date(from: string) {
            self = date
        } else {
            return nil
        }
    }
}

extension Date {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter
    }()
}
