import StoreKit

@available(iOS 11.2, *)
internal class MockSKProductSubscriptionPeriod : SKProductSubscriptionPeriod {
    private let _unit: SKProduct.PeriodUnit
    private let _numberOfUnits: Int
    
    internal init(unit: SKProduct.PeriodUnit, numberOfUnits: Int) {
        self._unit = unit
        self._numberOfUnits = numberOfUnits
    }
    
    override var unit: SKProduct.PeriodUnit {
        return self._unit
    }
    
    override var numberOfUnits: Int {
        return self._numberOfUnits
    }
}
