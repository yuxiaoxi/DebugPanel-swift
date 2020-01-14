#import <Foundation/Foundation.h>

char *encodeHexData(char *output_buf, const char *data, int data_size, BOOL up);

@interface Hex : NSObject

+ (NSString *)encodeHexData:(NSData *)data;
+ (NSString *)encodeHexString:(NSString *)str;

+ (NSData *)decodeHexString:(NSString *)hex;
+ (NSString *)decodeHexToString:(NSString *)hex;

@end
