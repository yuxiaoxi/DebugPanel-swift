//
//  LogFormat.swift
//  LingoLog
//
//  Created by Chun on 2019/1/10.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

import Foundation
import LingoLogPrivate

protocol LogFormattable {
  func format(logInfo: LogInfo, message: String) -> String
}

class LogFormatter: LogFormattable {
  
  func format(logInfo: LogInfo, message: String) -> String {
    var formatMessage = "[\(getLevelDisplay(logInfo.level))][\(getTimeDisplay(logInfo.timeval))][\(getThreadMessageDisplay(logInfo))]"
    if let tag = logInfo.tag {
      formatMessage += "[\(tag)]"
    }
    formatMessage += "["
    formatMessage += "\(logInfo.filename), "
    formatMessage += "\(logInfo.funcname), "
    formatMessage += "\(logInfo.line)] \(message)"
    return formatMessage
  }
  
  private func getThreadMessageDisplay(_ logInfo: LogInfo) -> String {
    var threadMessage = "\(logInfo.tid)"
    if LingoLogHelper.mainThreadId() == logInfo.tid {
      threadMessage += "*"
    }
    return threadMessage
  }
  
  private func getTimeDisplay(_ timeval: timeval) -> String {
    let usecDisplay = String(format: "%.3d", timeval.tv_usec / 1000)
    var sec = timeval.tv_sec
    let tm: tm! = localtime(&sec)?.pointee
    return "\(1900 + tm.tm_year)-\(1 + tm.tm_mon)-\(tm.tm_mday) \(tm.tm_hour):\(tm.tm_min):\(tm.tm_sec).\(usecDisplay)"
  }
  
  private func getLevelDisplay(_ level: LogLevel) -> String {
    switch level {
    case .verbose:
      return "Verbose"
    case .debug:
      return "Debug"
    case .info:
      return "Info"
    case .warning:
      return "Warning"
    case .error:
      return "Error"
    }
  }

}
