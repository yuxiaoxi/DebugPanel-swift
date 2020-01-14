//
//  Logger.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/21.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

public extension RussellLogger {
  
  enum Level: Int {
    case debug = 1
    case info
    case warning
    case error
  }
}

public protocol RussellLoggerOutput {
  func log(level: RussellLogger.Level, file: String, function: String, line: Int, message: () -> Any)
}

private struct ConsoleOutput: RussellLoggerOutput {
  func log(level: RussellLogger.Level, file: String, function: String, line: Int, message: () -> Any) {
    print("[Russell][\(level)] \(message())")
  }
}

public enum RussellLogger {
  
  private static var output: RussellLoggerOutput = ConsoleOutput()
  public static func setup(output: RussellLoggerOutput) {
    self.output = output
  }
  
  internal static func debug(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
    output.log(level: .debug, file: file, function: function, line: line, message: message)
  }
  
  internal static func info(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
    output.log(level: .info, file: file, function: function, line: line, message: message)
  }
  
  internal static func warning(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
    output.log(level: .warning, file: file, function: function, line: line, message: message)
  }
  
  internal static func error(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
    output.log(level: .error, file: file, function: function, line: line, message: message)
  }
}

internal typealias Logger = RussellLogger
