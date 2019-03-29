@testable import MerchantKit

extension ASN1.Parser.PayloadDescriptor {
    internal var byte: UInt8 {
        // Encoded: |Domain_|IsC|TagNumber__________|
            
        var byte: UInt8 = 0
        
        byte += self.domain.rawValue << 6
        
        let isConstructedByte: UInt8 = self.valueKind == .constructed ? 1 : 0
        byte += isConstructedByte << 5
        
        byte += self.tag.rawType
        
        return byte
    }
}
