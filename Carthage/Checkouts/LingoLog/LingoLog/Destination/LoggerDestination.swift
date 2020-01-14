//
//  LoggerDestination.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

class LoggerDestination: NSObject {
  
  // MARK: - Hashable
  
  override var hash: Int {
    return defaultHashValue
  }

  var defaultHashValue: Int { return 0 }
  
  static func == (lhs: LoggerDestination, rhs: LoggerDestination) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  // MARK: - Log
  
  var logFilter: LogFilterable = LogFilter(filterRule: LogFilterRule())
  
  var logFomatter: LogFormattable = LogFormatter()
  
  var asynchronously: Bool = true
  // each log provide own background thread for better performance
  let queue: DispatchQueue
  
  override init() {
    let uuid = UUID().uuidString
    let queueLabel = "LingoLog-queue-" + uuid
    queue = DispatchQueue(label: queueLabel)
  }
  
  func shouldBeLogged(logInfo: LogInfo) -> Bool {
    return logFilter.shouldBeLogged(logInfo: logInfo)
  }
  
  @discardableResult func send(logInfo: LogInfo, message: String) -> String {
    return logFomatter.format(logInfo: logInfo, message: message)
  }
  
}
