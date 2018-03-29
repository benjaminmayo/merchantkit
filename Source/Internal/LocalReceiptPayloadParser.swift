import Foundation

/// Parse a payload from a local App Store receipt file.
internal struct LocalReceiptPayloadParser {
    init() {
        
    }
    
    func receipt(from payload: Data) throws -> Receipt {
        var entries = [ReceiptEntry]()
        
        let attributes = try ASN1ReceiptAttributeSet(in: payload, of: ReceiptAttributeType.self)
        
        for attribute in attributes {
            switch attribute.type {
                case .inAppPurchases:
                    var productIdentifier: String?
                    var expiryDate: Date?
                
                    let purchaseAttributes = try ASN1ReceiptAttributeSet(in: attribute.byteValue, of: InAppPurchaseAttributeType.self)
                
                    for attribute in purchaseAttributes {
                        switch attribute.type {
                            case .productIdentifier:
                                productIdentifier = attribute.stringValue
                            case .subscriptionExpirationDate:
                                expiryDate = attribute.dateValue
                            default:
                                break
                        }
                    }
                    
                    let entry = ReceiptEntry(productIdentifier: productIdentifier!, expiryDate: expiryDate)
                    entries.append(entry)
                default:
                    break
            }
        }
        
        return ConstructedReceipt(from: entries)
    }
}

extension LocalReceiptPayloadParser {
    private enum ReceiptAttributeType : Int {
        case bundleIdentifier = 2
        case applicationVersion = 3
        case opaqueValue = 4
        case sha1Hash = 5
        case inAppPurchases = 17
        case originalApplicationVersion = 19
        case creationDate = 12
        case expirationDate = 21
    }
    
    private enum InAppPurchaseAttributeType : Int {
        case quantity = 1701
        case productIdentifier = 1702
        case transactionIdentifier = 1703
        case originalTransactionIdentifier = 1705
        case purchaseDate = 1704
        case originalPurchaseDate = 1706
        case subscriptionExpirationDate = 1708
        case cancellationDate = 1712
        case webOrderLineItemIdentifier = 1711
    }
}
