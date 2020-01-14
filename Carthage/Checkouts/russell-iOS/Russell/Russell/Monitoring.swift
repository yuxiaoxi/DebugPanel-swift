//
//  Monitoring.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/16.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public protocol RussellMonitorOutput {
  func track(errorDomain: String, errorCode: Int32, errorDescription: String)
}

public enum RussellMonitor {
  
  private static var output: RussellMonitorOutput = LoggerMonitorOutput()
  public static func setup(output: RussellMonitorOutput) {
    self.output = output
  }
  
  internal static func trackError(_ error: RussellMonitorError, description: String) {
    output.track(errorDomain: "Russell-iOS", errorCode: error.rawValue, errorDescription: description)
  }
}

internal typealias Monitor = RussellMonitor

internal final class LoggerMonitorOutput: RussellMonitorOutput {
  
  func track(errorDomain: String, errorCode: Int32, errorDescription: String) {
    Logger.error("Russell internal error(\(errorCode)): \(errorDescription)")
  }
}

// MARK: - Monitor Error Code

enum RussellMonitorError: Int32 {
  /// response json 解析失败
  case decodingFailure = 1
  /// 调用路径出错(使用不当 或者 异常用户行为)
  case unexpectedBehavior
}
