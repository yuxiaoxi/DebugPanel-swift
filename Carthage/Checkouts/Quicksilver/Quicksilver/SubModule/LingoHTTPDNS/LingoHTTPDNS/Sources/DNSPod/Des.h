#import <Foundation/Foundation.h>

@interface Des : NSObject

- (NSData *)encrypt:(NSData *)input;

- (NSData *)decrpyt:(NSData *)input;

- (instancetype)init:(NSData *)key;

@end
