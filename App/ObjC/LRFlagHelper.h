#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Builds flag emoji from currency codes. Written in Objective-C on purpose: many bank apps
/// still have Objective-C code, and Swift calls it through the bridging header.
@interface LRFlagHelper : NSObject

/// "USD" -> 🇺🇸, "EUR" -> 🇪🇺. The first two letters of most currency codes are the
/// country's ISO region code. Returns an empty string for anything that isn't A-Z.
+ (NSString *)flagForCurrencyCode:(NSString *)code NS_SWIFT_NAME(flag(forCurrencyCode:));

@end

NS_ASSUME_NONNULL_END
