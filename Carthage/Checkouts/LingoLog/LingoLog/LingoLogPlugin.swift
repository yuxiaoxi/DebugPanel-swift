//
//  LingoLogPlugin.swift
//  LingoLog
//
//  Created by Chun on 2019/1/11.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

import Foundation

/// 外部可以通过注入 LingoLogPlugin 的实现来捕获 LingoLog 的关键流程, 用于一些额外的扩展
public protocol LingoLogPlugin: class {

  /// 捕获 LingoLog 内部异常，可以同步数据到打点服务进行查询, 默认实现为空。
  /// 该方法调用时机为内部出现错误的线程。
  ///
  /// - Parameters:
  ///   - errorCode: error code
  ///   - message: error message
  func handleLingoLogError(_ errorCode: Int, message: String?)
  
  /// 捕获 LingoLog 内部接收到的每一条日志信息。该方法调用的线程为日志信息输出的线程。默认实现为空。
  func handleLog(level: LogLevel, message: Any, tag: String?, file: String, function: String, line: Int)
}

extension LingoLogPlugin {
  
  public func handleLingoLogError(_ errorCode: Int, message: String?) {
  }

  public func handleLog(level: LogLevel, message: Any, tag: String?, file: String, function: String, line: Int) {
  }
}
