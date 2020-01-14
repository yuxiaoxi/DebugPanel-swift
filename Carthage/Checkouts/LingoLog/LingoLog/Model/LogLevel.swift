//
//  LogLevel.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

/// Log Level
///
/// - verbose: The lowest priority level. Use this one for contextual information.
/// - debug: Use this level for printing variables and results that will help you fix a bug or solve a problem.
/// - info: This is typically used for information useful in a more general support context. In other words, info that is useful for non developers looking into issues.
/// - warning: Use this log level when reaching a condition that won’t necessarily cause a problem but strongly leads the app in that direction.
/// - error: The most serious and highest priority log level. Use this only when your app has triggered a serious error.
public enum LogLevel: Int {
  case verbose = 0
  case debug = 1
  case info = 2
  case warning = 3
  case error = 4
}
