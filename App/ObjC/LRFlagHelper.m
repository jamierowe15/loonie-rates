#import "LRFlagHelper.h"

@implementation LRFlagHelper

+ (NSString *)flagForCurrencyCode:(NSString *)code {
    if (code.length < 2) {
        return @"";
    }
    NSString *region = [[code substringToIndex:2] uppercaseString];
    NSMutableString *flag = [NSMutableString string];
    for (NSUInteger index = 0; index < region.length; index++) {
        unichar letter = [region characterAtIndex:index];
        if (letter < 'A' || letter > 'Z') {
            return @"";
        }
        // A flag is two "regional indicator" symbols: U+1F1E6 is 🇦, U+1F1E7 is 🇧, and so on.
        uint32_t scalar = NSSwapHostIntToLittle(0x1F1E6 + (uint32_t)(letter - 'A'));
        NSString *symbol = [[NSString alloc] initWithBytes:&scalar
                                                    length:sizeof(scalar)
                                                  encoding:NSUTF32LittleEndianStringEncoding];
        if (symbol == nil) {
            return @"";
        }
        [flag appendString:symbol];
    }
    return flag;
}

@end
