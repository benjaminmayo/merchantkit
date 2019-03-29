//
//  MockSKProductDiscountWithNilPriceLocale.m
//  MerchantKitTests
//
//  Created by Benjamin on 21/02/2019.
//  Copyright © 2019 Benjamin Mayo. All rights reserved.
//

#import "MockSKProductDiscountWithNilPriceLocale.h"

@interface MockSKProductDiscountWithNilPriceLocale()

@property (nonatomic, strong) NSDecimalNumber *_price;
@property (nonatomic, strong) SKProductSubscriptionPeriod *_subscriptionPeriod;
@property (nonatomic) NSInteger _numberOfPeriods;
@property (nonatomic) SKProductDiscountPaymentMode _paymentMode;

@end

@implementation MockSKProductDiscountWithNilPriceLocale

- (instancetype)initWithPrice:(NSDecimalNumber *)price subscriptionPeriod:(SKProductSubscriptionPeriod *)subscriptionPeriod numberOfPeriods:(NSUInteger)numberOfPeriods paymentMode:(SKProductDiscountPaymentMode)paymentMode {
    self = [super init];
    
    if (self) {
        self._price = price;
        self._subscriptionPeriod = subscriptionPeriod;
        self._numberOfPeriods = numberOfPeriods;
        self._paymentMode = paymentMode;
    }
    
    return self;
}

- (NSDecimalNumber *)price {
    return self._price;
}

- (NSLocale *)priceLocale {
    return nil;
}

- (SKProductSubscriptionPeriod *)subscriptionPeriod {
    return self._subscriptionPeriod;
}

- (NSUInteger)numberOfPeriods {
    return self._numberOfPeriods;
}

- (SKProductDiscountPaymentMode)paymentMode {
    return self._paymentMode;
}

@end
