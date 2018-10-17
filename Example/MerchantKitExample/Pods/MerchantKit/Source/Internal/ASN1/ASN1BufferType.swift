extension ASN1 {
    enum BufferType : UInt8 {
        case eoc = 0x00
        case boolean = 0x01
        case integer = 0x02
        case bitString = 0x03
        case octetString = 0x04
        case null = 0x05
        case objectIdentifier = 0x06
        case objectDescriptor = 0x07
        case externalReference = 0x08
        case real = 0x09
        case enumerated = 0x0a
        case embeddedPDV = 0x0b
        case utf8String = 0x0c
        case relativeObjectIdentifier = 0x0d
        case sequence = 0x10
        case set = 0x11
        case numericString = 0x12
        case printableString = 0x13
        case teletexString = 0x14
        case videoTextString = 0x15
        case ia5String = 0x16
        case utcTime = 0x17
        case generalizedTime = 0x18
        case graphicString = 0x19
        case visibleString = 0x1a
        case generalString = 0x1b
        case universalString = 0x1c
        case bitmapString = 0x1e
        case usesLongForm = 0x1f
    }
}
