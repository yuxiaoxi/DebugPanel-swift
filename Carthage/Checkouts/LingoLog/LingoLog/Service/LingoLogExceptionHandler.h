//
//  LingoLogExceptionHandler.h
//  LingoLog
//
//  Created by Chun on 2019/1/15.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LingoLogExceptionHandlerDelegate <NSObject>

- (void)handleException:(nonnull NSException *)exception;

- (void)handleSignal:(int)signal;

@end

@interface LingoLogExceptionHandler : NSObject

@property (nonatomic, weak) id<LingoLogExceptionHandlerDelegate> _Nullable delegate;

+ (nonnull instancetype)sharedInstance;

- (void)start;

- (void)stop;

@end

@interface LingoLogHelper : NSObject

+ (uintptr_t)currentThreadId;

+ (uintptr_t)mainThreadId;

@end
