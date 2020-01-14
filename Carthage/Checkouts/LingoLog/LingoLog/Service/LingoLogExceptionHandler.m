//
//  LingoLogExceptionHandler.m
//  LingoLog
//
//  Created by Chun on 2019/1/15.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

#include <TargetConditionals.h>
#include <signal.h>
#include <execinfo.h>
#import "LingoLogExceptionHandler.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

typedef void (*SignalHandler)(int signo, siginfo_t *info, void *context);

static SignalHandler previousSignalHandler = NULL;

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler;

static BOOL exceptionHandled = NO;

@interface LingoLogExceptionHandler ()

@property (nonatomic, assign) BOOL isStarted;

@end

@implementation LingoLogExceptionHandler

+ (nonnull instancetype)sharedInstance {
  static LingoLogExceptionHandler *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[LingoLogExceptionHandler alloc] init];
  });
  return shared;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.isStarted = NO;
  }
  return self;
}

- (void)start {
  if (!self.isStarted) {
    [self initSignalHandler];
    [self initExceptionHandler];
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV || TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHandler) name:UIApplicationDidBecomeActiveNotification object:nil];
#else
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHandler) name:NSApplicationDidBecomeActiveNotification object:nil];
#endif
    self.isStarted = YES;
  }
}

- (void)stop {
  if (self.isStarted) {
    if (previousUncaughtExceptionHandler && previousUncaughtExceptionHandler != handleExceptions) {
      NSSetUncaughtExceptionHandler(previousUncaughtExceptionHandler);
    }
    if (previousSignalHandler && previousSignalHandler != signalHandler) {
      struct sigaction newSignalAction;
      memset(&newSignalAction, 0,sizeof(newSignalAction));
      newSignalAction.sa_sigaction = previousSignalHandler;
      newSignalAction.sa_flags = SA_NODEFER | SA_SIGINFO;
      sigemptyset(&newSignalAction.sa_mask);
      [self handleAllSignals:newSignalAction];
    }
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV || TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
#else
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
#endif
    self.isStarted = NO;
  }
}

void handleExceptions(NSException *exception) {
  exceptionHandled = YES;

  if ([LingoLogExceptionHandler sharedInstance].delegate != nil && exception != nil) {
    [[LingoLogExceptionHandler sharedInstance].delegate handleException:exception];
  }
  if (previousUncaughtExceptionHandler && previousUncaughtExceptionHandler != handleExceptions) {
    previousUncaughtExceptionHandler(exception);
  }
}

void signalHandler(int sig, siginfo_t *info, void *context) {
  if ([LingoLogExceptionHandler sharedInstance].delegate != nil && !exceptionHandled) {
    [[LingoLogExceptionHandler sharedInstance].delegate handleSignal:sig];
  }
  if (previousSignalHandler && previousSignalHandler != signalHandler) {
    previousSignalHandler(sig, info, context);
  } else {
    NSSetUncaughtExceptionHandler(nil);
    signal(sig, SIG_DFL);
    kill(getpid(), SIGKILL);
  }
}

- (void)initSignalHandler {
  struct sigaction old_action;
  sigaction(SIGABRT, NULL, &old_action);
  if (old_action.sa_flags & SA_SIGINFO) {
    previousSignalHandler = old_action.sa_sigaction;
  }
  if (previousSignalHandler == nil || previousSignalHandler != signalHandler) {
    struct sigaction newSignalAction;
    memset(&newSignalAction, 0,sizeof(newSignalAction));
    newSignalAction.sa_sigaction = signalHandler;
    newSignalAction.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&newSignalAction.sa_mask);
    [self handleAllSignals:newSignalAction];
  }
}

- (void)initExceptionHandler {
  previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
  if (previousUncaughtExceptionHandler == nil || previousUncaughtExceptionHandler != handleExceptions) {
    NSSetUncaughtExceptionHandler(&handleExceptions);
  }
}

- (void)handleAllSignals:(struct sigaction) action {
  sigaction(SIGABRT, &action, NULL);
  sigaction(SIGBUS, &action, NULL);
  sigaction(SIGFPE, &action, NULL);
  sigaction(SIGILL, &action, NULL);
  sigaction(SIGSEGV, &action, NULL);
  sigaction(SIGSYS, &action, NULL);
  sigaction(SIGTRAP, &action, NULL);
}

- (void)checkHandler {
  [self initSignalHandler];
  [self initExceptionHandler];
}

@end

@implementation LingoLogHelper

+ (uintptr_t)currentThreadId {
  return (uintptr_t)[NSThread currentThread];
}

+ (uintptr_t)mainThreadId {
  return (uintptr_t)[NSThread mainThread];
}

@end
