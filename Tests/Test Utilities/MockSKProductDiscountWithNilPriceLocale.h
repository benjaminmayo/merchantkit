//
//  MockSKProductDiscountWithNilPriceLocale.h
//  MerchantKitTests
//
//  Created by Benjamin on 21/02/2019.
//  Copyright © 2019 Benjamin Mayo. All rights reserved.
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.2))
@interface MockSKProductDiscountWithNilPriceLocale : SKProductDiscount

- (instancetype)initWithPrice:(NSDecimalNumber *)price subscriptionPeriod:(SKProductSubscriptionPeriod *)subscriptionPeriod numberOfPeriods:(NSUInteger)numberOfPeriods paymentMode:(SKProductDiscountPaymentMode)paymentMode;

@end

NS_ASSUME_NONNULL_END
