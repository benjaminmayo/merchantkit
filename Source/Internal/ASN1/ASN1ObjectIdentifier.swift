import Foundation

extension ASN1 {
    struct ObjectIdentifier : Equatable, CustomStringConvertible {
        private let bytes: Data
        
        init(bytes: Data) {
            self.bytes = bytes.subdata(in: bytes.startIndex..<bytes.endIndex)
        }
        
        var description: String {
            return self.defaultDescription(typeName: "ASN1.ObjectIdentifier", withProperties: ("stringValue", self.stringValue ?? "nil"))
        }
        
        var stringValue: String? {
            var components = [UInt]()
            
            let firstByte = UInt(self.bytes.first!)
            
            components.append(firstByte / 40)
            components.append(firstByte % 40)
            
            var idx = self.bytes.startIndex + 1
            let end = self.bytes.endIndex
            
            while idx < end {
                var num: UInt = 0
                
                while true {
                    if (idx >= end) {
                        return nil
                    }
                    
                    let byte = UInt(self.bytes[idx])
                    idx += 1
                    
                    num |= byte & 0x7f
                    
                    if ((byte & 0x80) == 0) {
                        break
                    }
                    
                    num <<= 7
                }
                
                components.append(num)
            }
            
            return components.map { String($0) }.joined(separator: ".")
        }
    }
}

