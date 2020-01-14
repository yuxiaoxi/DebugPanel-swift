//
//  LoggerService.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation
import LingoLogPrivate

class LoggerService: NSObject {
  
  static let shared = LoggerService()
  
  var destinations = Set<LoggerDestination>()

  var plugins: [LingoLogPlugin]?
  
  // MARK: Crash Capture
  
  func configCrashCapture(open: Bool, crashTag: String) {
    self.crashTag = crashTag
    
    if open {
      CrashCaptureService.shared.add(delegate: self)
    } else {
      CrashCaptureService.shared.remove(delegate: self)
    }
  }
  
  func handleErrorMessage(errorCode: Int, message: String?) {
    if let plugins = plugins, plugins.count > 0 {
      plugins.forEach { plugin in
        plugin.handleLingoLogError(errorCode, message: message)
      }
    }
  }
  
  func handleLog(level: LogLevel, message: Any, tag: String?, file: String, function: String, line: Int) {
    if let plugins = plugins {
      for plugin in plugins {
        plugin.handleLog(level: level, message: message, tag: tag, file: file, function: function, line: line)
      }
    }
  }
  
  // MARK: Log
  
  func dispatchSend(level: LogLevel, message: @autoclosure () -> Any, tag: String?, file: String, function: String, line: Int, asynchronously: Bool? = nil) {
    handleLog(level: level, message: message(), tag: tag, file: file, function: function, line: line)

    let log = "\(message())"
    var time: timeval = Darwin.timeval()
    gettimeofday(&time, nil)
    let threadId = LingoLogHelper.currentThreadId()
    let logInfo = LogInfo(level: level, filename: LoggerService.fileNameWithoutSuffix(file), funcname: function, line: line, timeval: time, tid: threadId, tag: tag, isCrashLog: tag == crashTag)
    for destination in destinations {
      let async: Bool = asynchronously ?? destination.asynchronously
      if async {
        destination.queue.async {
          self.sendLog(logInfo: logInfo, log: log, with: destination)
        }
      } else {
        destination.queue.sync {
          self.sendLog(logInfo: logInfo, log: log, with: destination)
        }
      }
    }
  }
  
  /// returns the filename of a path
  class func fileNameOfFile(_ file: String) -> String {
    let fileParts = file.components(separatedBy: "/")
    if let lastPart = fileParts.last {
      return lastPart
    }
    return ""
  }
  
  /// returns the filename without suffix (= file ending) of a path
  class func fileNameWithoutSuffix(_ file: String) -> String {
    let fileName = fileNameOfFile(file)
    
    if !fileName.isEmpty {
      let fileNameParts = fileName.components(separatedBy: ".")
      if let firstPart = fileNameParts.first {
        return firstPart
      }
    }
    return ""
  }
  
  // MARK: - Private
  
  private var crashTag: String = "AppCrash"
  
  private override init() {
    super.init()
  }
  
  private func sendLog(logInfo: LogInfo, log: String, with destination: LoggerDestination) {
    if destination.shouldBeLogged(logInfo: logInfo) {
      destination.send(logInfo: logInfo, message: log)
    }
  }

}

extension LoggerService: CrashCaptureDelegate {
  
  func crashCaptureDidCatchCrash(with model: CrashModel) {
    dispatchSend(level: .error, message: model, tag: crashTag, file: #file, function: #function, line: #line, asynchronously: false)
  }
  
}
