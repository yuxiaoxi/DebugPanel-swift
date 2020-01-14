//
//  Logger.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

/// Use Logger API for logging
open class Logger {
  
  /// log contextual information (The lowest priority level)
  open class func verbose(_ message: @autoclosure () -> Any,
                          _ tag: String? = nil,
                          _ file: String = #file,
                          _ function: String = #function,
                          _ line: Int = #line) {
    Logger.log(level: .verbose, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
  /// log something which help during debugging (low priority)
  open class func debug(_ message: @autoclosure () -> Any,
                        _ tag: String? = nil,
                        _ file: String = #file,
                        _ function: String = #function,
                        _ line: Int = #line) {
    Logger.log(level: .debug, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
  /// log something which you are really interested but which is not an issue or error (normal priority)
  open class func info(_ message: @autoclosure () -> Any,
                       _ tag: String? = nil,
                       _ file: String = #file,
                       _ function: String = #function,
                       _ line: Int = #line) {
    Logger.log(level: .info, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
  /// log something which may cause big trouble soon (high priority)
  open class func warning(_ message: @autoclosure () -> Any,
                          _ tag: String? = nil,
                          _ file: String = #file,
                          _ function: String = #function,
                          _ line: Int = #line) {
    Logger.log(level: .warning, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
  /// log something which will keep you awake at night (highest priority)
  open class func error(_ message: @autoclosure () -> Any,
                        _ tag: String? = nil,
                        _ file: String = #file,
                        _ function: String = #function,
                        _ line: Int = #line) {
    Logger.log(level: .error, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
  open class func log(level: LogLevel, message: @autoclosure () -> Any, tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.dispatchSend(level: level, message: message(), tag: tag, file: file, function: function, line: line)
  }
  
}

extension Logger {
  open class func verbose(_ message: @autoclosure () -> Any?,
                          _ tag: String? = nil,
                          _ file: String = #file,
                          _ function: String = #function,
                          _ line: Int = #line) {
    if let message = message() {
      log(level: .verbose, message: message, tag: tag, file: file, function: function, line: line)
    } else {
      log(level: .verbose, message: "[nil]", tag: tag, file: file, function: function, line: line)
    }
  }
  
  /// log something which help during debugging (low priority)
  open class func debug(_ message: @autoclosure () -> Any?,
                        _ tag: String? = nil,
                        _ file: String = #file,
                        _ function: String = #function,
                        _ line: Int = #line) {
    if let message = message() {
      log(level: .debug, message: message, tag: tag, file: file, function: function, line: line)
    } else {
      log(level: .debug, message: "[nil]", tag: tag, file: file, function: function, line: line)
    }
  }
  
  /// log something which you are really interested but which is not an issue or error (normal priority)
  open class func info(_ message: @autoclosure () -> Any?,
                       _ tag: String? = nil,
                       _ file: String = #file,
                       _ function: String = #function,
                       _ line: Int = #line) {
    if let message = message() {
      log(level: .info, message: message, tag: tag, file: file, function: function, line: line)
    } else {
      log(level: .info, message: "[nil]", tag: tag, file: file, function: function, line: line)
    }
  }
  
  /// log something which may cause big trouble soon (high priority)
  open class func warning(_ message: @autoclosure () -> Any?,
                          _ tag: String? = nil,
                          _ file: String = #file,
                          _ function: String = #function,
                          _ line: Int = #line) {
    if let message = message() {
      log(level: .warning, message: message, tag: tag, file: file, function: function, line: line)
    } else {
      log(level: .warning, message: "[nil]", tag: tag, file: file, function: function, line: line)
    }
  }
  
  /// log something which will keep you awake at night (highest priority)
  open class func error(_ message: @autoclosure () -> Any?,
                        _ tag: String? = nil,
                        _ file: String = #file,
                        _ function: String = #function,
                        _ line: Int = #line) {
    if let message = message() {
      log(level: .error, message: message, tag: tag, file: file, function: function, line: line)
    } else {
      log(level: .error, message: "[nil]", tag: tag, file: file, function: function, line: line)
    }
  }
  
}
