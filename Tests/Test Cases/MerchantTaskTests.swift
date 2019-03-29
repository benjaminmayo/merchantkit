import XCTest
import Foundation
@testable import MerchantKit

class MerchantTaskTests : XCTestCase {
    func testMerchantTaskAssertIfStartedBefore() {
        let expectation = self.expectation(description: "fatalError thrown")
        
        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        let testingQueue = DispatchQueue(label: "testing queue") // testing MerchantKitFatalError requires dispatch to a non-main thread

        testingQueue.async {
            let task = MockMerchantTask()
            task.start()
            task.start() // should trap here
        }
        
        self.wait(for: [expectation], timeout: 2)
        
        MerchantKitFatalError.customHandler = nil 
    }
    
    func testStartAndResignNonActivatedTaskDoesNotConfuseMerchant() {
        let mockDelegate = MockMerchantDelegate()
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate)
        let mockTask = MockMerchantTask()
        mockTask.start()
        
        merchant.taskDidStart(mockTask)
        merchant.taskDidResign(mockTask)
    }
}

private class MockMerchantTask : MerchantTask {
    var isStarted: Bool = false
    
    init() {
        
    }
    
    func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
    }
}
