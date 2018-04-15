#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

//! Project version number for MerchantKit.
FOUNDATION_EXPORT double MerchantKitVersionNumber;

//! Project version string for MerchantKit.
FOUNDATION_EXPORT const unsigned char MerchantKitVersionString[];

// This trampoline function exists to workaround an incorrect nullability annotation in the `SKProductDiscount` class declaration. Related bug report: rdar://39410422
static inline NSLocale *_Nullable priceLocaleFromProductDiscount(SKProductDiscount *_Nonnull discount) NS_AVAILABLE_IOS(11_2) {
    return discount.priceLocale;
}
