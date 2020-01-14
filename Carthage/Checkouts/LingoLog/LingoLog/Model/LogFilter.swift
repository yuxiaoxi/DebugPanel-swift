//
//  LoggerFilter.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

public struct LogFilterRule {
  
  /// 使用 TagComparison 时需要使用的 Tag Model
  public struct TagType {
    public let tag: String
    public let level: LogLevel
    
    public init(tag: String, level: LogLevel) {
      self.tag = tag
      self.level = level
    }
  }
  
  /// Tag 信息过滤
  ///
  /// - excludes: 当前 TagType 下的日志将会根据 TagType 设置的 level 进行过滤 (logLevel <= tagType.level && logTag == tagType.tag 将会被过滤)，其他日志根据 minLevel 判断是否需要过滤
  /// - equals: 仅有当前 TagType 下的日志会根据 TagType 设置的 level 作为 minLevel 判断是否需要过滤 (logLevel >= tagType.level && logTag == tagType.tag 将会被收集). 当 `onlyEquals` 为 `true` 时，其他日志直接被过滤。 当 `onlyEquals` 为 `false` 时，其他日志根据 minLevel 判断是否需要过滤
  public enum TagComparison {
    case excludes(tagTypes: [TagType])
    case equals(tagTypes: [TagType], onlyEquals: Bool)
  }
  
  /// 初始化日志过滤规则
  ///
  /// - Parameters:
  ///   - minLevel: 当前日志最小支持的 LogLevel，低于的 LogLvel 会被过滤。
  ///   - comparison: 可以过滤指定的日志按照 Tag 信息过滤。
  public init(minLevel: LogLevel = .debug, tagComparison: TagComparison? = nil) {
    self.minLevel = minLevel
    self.tagComparison = tagComparison
  }
  
  public let minLevel: LogLevel
  public let tagComparison: TagComparison?
}

// MARK: - LogFilterable

protocol LogFilterable {
  func shouldBeLogged(logInfo: LogInfo) -> Bool
}

class LogFilter: LogFilterable {
  
  let filterRule: LogFilterRule
  
  init(filterRule: LogFilterRule) {
    self.filterRule = filterRule
  }
  
  func shouldBeLogged(logInfo: LogInfo) -> Bool {
    if let comparison = filterRule.tagComparison {
      switch comparison {
      case .equals(let tagTypes, let onlyEquals):
        if let messageTag = logInfo.tag {
          for tagType in tagTypes where messageTag == tagType.tag {
            return logInfo.level.rawValue >= tagType.level.rawValue
          }
        }
        return onlyEquals ? false : logInfo.level.rawValue >= filterRule.minLevel.rawValue
      case .excludes(let tagTypes):
        if let messageTag = logInfo.tag {
          for tagType in tagTypes where messageTag == tagType.tag {
            return logInfo.level.rawValue > tagType.level.rawValue
          }
        }
        return logInfo.level.rawValue >= filterRule.minLevel.rawValue
      }
    } else {
      return logInfo.level.rawValue >= filterRule.minLevel.rawValue
    }
  }
  
}
