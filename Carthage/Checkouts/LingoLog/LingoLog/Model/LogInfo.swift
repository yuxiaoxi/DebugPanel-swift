//
//  LogInfo.swift
//  LingoLog
//
//  Created by Chun on 2019/1/11.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

import Foundation

/// 每条日志的基础信息
struct LogInfo {
  let level: LogLevel
  let filename: String
  let funcname: String
  let line: Int
  let timeval: timeval
  let tid: UInt
  let tag: String?
  let isCrashLog: Bool
  
  init(level: LogLevel, filename: String, funcname: String, line: Int, timeval: timeval, tid: UInt, tag: String?, isCrashLog: Bool) {
    self.level = level
    self.filename = filename
    self.funcname = funcname
    self.line = line
    self.timeval = timeval
    self.tid = tid
    self.tag = tag
    self.isCrashLog = isCrashLog
  }

}
