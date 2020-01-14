//
//  LoggerTool.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit
#endif

/// User LoggerTool to config LingoLog service.
/// All Methods need to call on Main Thread.
public class LoggerTool {

  #if os(iOS) || os(tvOS) || os(watchOS)
  /// get developer viewController for fetching logs with LoggerFileDestination
  ///
  /// - Returns: Debug ViewController
  public static func getLogPanel() -> UIViewController {
    return LoggerDeveloperViewController(style: .plain)
  }
  
  /// 增加日志在 AirLog 的日志输出方式。该方法应该只被调用一次。日志输出仅支持同步的形式。LiveLog 模块不应该发布在线上环境！
  ///
  /// - Parameters:
  ///   - filterRule: 日志的 filter 参数，默认值为空，默认的 filterRule 为 `LogFilterRule(minLevel: .debug)`
  public static func appendLiveLogOutput(filterRule: LogFilterRule? = nil) {
    let destination = LiveLogDestination()
    insertDestination(destination, filterRule: filterRule, asynchronously: false)
  }
  
  #elseif os(macOS)
  
  /// 获取所有 FileOutout 输出的日志文件路径
  ///
  /// - Returns: 日志文件路径数组
  public static func getFileOutputLogFiles() -> [String] {
    return LoggerFileDestination.getAllAvailableLogFilePaths()
  }
  
  #endif

  /// 是否打开 Crash 捕获，打开后 crash 信息将会被捕获到 log 中。外部应当在 `func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)` 的时机进行配置。
  ///
  /// - Parameter open: 是否打开
  /// - Parameter crashLogTag: crash 日志所对应的 Tag，默认值为 `AppCrash`
  public static func configCrashCapture(open: Bool, crashLogTag tag: String = "AppCrash") {
    LoggerService.shared.configCrashCapture(open: open, crashTag: tag)
  }
  
  /// 外部可以通过注入 LingoLogPlugin 的实现来捕获 LingoLog 的关键流程, 用于一些额外的扩展
  public static var logPlugins: [LingoLogPlugin]? {
    get {
      return LoggerService.shared.plugins
    }
    set {
      LoggerService.shared.plugins = newValue
    }
  }
  
  /// 增加日志在 IDE 中的输出，该方法调用多次无效。 IDE 模块应该仅在项目的测试环境下加入！
  ///
  /// - Parameters:
  ///   - filterRule: 日志的 filter 参数，默认值为空，默认的 filterRule 为 `LogFilterRule(minLevel: .debug)`
  ///   - asynchronously: 默认为 true
  public static func appendIDEOutput(filterRule: LogFilterRule? = nil, asynchronously: Bool = true) {
    let destination = LoggerXcodeDestination()
    insertDestination(destination, filterRule: filterRule, asynchronously: asynchronously)
  }
  
  /// 增加日志在文件中的输出，该方法可以调用多次。调用方可以通过配合不同的 filter 把不同模块的日志输出到不同文件中。FileOutput 模块应该仅在项目的测试环境下加入！
  /// FileOutput 产生的所有日志可以通过 LogPanel 模块中查看。
  ///
  /// - Parameters:
  ///   - filename: 日志的输出文件名
  ///   - filterRule: 日志的 filter 参数，默认值为空，默认的 filterRule 为 `LogFilterRule(minLevel: .debug)`
  ///   - asynchronously: 默认为 true
  public static func appendFileOutput(filename: String, filterRule: LogFilterRule? = nil, asynchronously: Bool = true) {
    let destination = LoggerFileDestination(filename: filename)
    insertDestination(destination, filterRule: filterRule, asynchronously: asynchronously)
  }

}

extension LoggerTool {
  
  @discardableResult private static func insertDestination(_ destination: LoggerDestination, filterRule: LogFilterRule?, asynchronously: Bool) -> Bool {
    if !LoggerService.shared.destinations.contains(destination) {
      if let filterRule = filterRule {
        destination.logFilter = LogFilter(filterRule: filterRule)
      }
      destination.asynchronously = asynchronously
      LoggerService.shared.destinations.insert(destination)
      return true
    } else {
      return false
    }
  }

}
