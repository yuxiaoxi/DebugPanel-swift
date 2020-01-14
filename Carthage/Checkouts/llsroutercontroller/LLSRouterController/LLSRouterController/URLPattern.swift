//
//  URLPattern.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/5.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

public enum URLPatternType: Int {
  case URLPatternTypeClass = 0 // host对应创建Class
  case URLPatternTypeHttp = 1 // host对应创建webviewController
  case PatternTypeHtmlZip = 2 // host对应离线下载html zip包
}

var defaultWebViewControllerClass: AnyClass? = nil
public class URLPattern: NSObject {
  
  public var key: String
  public var type: URLPatternType
  public var patternString: String
  public var targetClass: AnyClass? {
    if self.type == URLPatternType.URLPatternTypeHttp || self.type == URLPatternType.PatternTypeHtmlZip {
      #if DEBUG
        if defaultWebViewControllerClass == nil {
          print("default WebViewController Class is not assigned, please call [NVURLPattern setDefaultWebViewControllerClass:] method first!!")
          return nil
        }
      #endif
      return defaultWebViewControllerClass
    }
    if patternString.count < 1 {
      return nil
    }
    if type == URLPatternType.URLPatternTypeClass {
      return NSClassFromString(patternString)
    } else {
      return nil
    }
  }
  
  public var version: Int?
  
  required init(string: String, type: URLPatternType, key: String) {
    self.key = key
    self.type = type
    self.patternString = string
  }

}

// MARK: Public Method
public extension URLPattern {
  
  static func setDefaultWebViewControllerClass(webControllerClass: AnyClass) -> Void {
    defaultWebViewControllerClass = webControllerClass
  }
  
  static func patternWithClass(className: String, key: String) -> URLPattern {
    return self.init(string: className, type: .URLPatternTypeClass, key: key)
  }
  
  static func patternWithHttp(url: String, key: String) -> URLPattern {
    return self.init(string: url, type: .URLPatternTypeHttp, key: key)
  }
  
  static func patternWithHtmlZip(urlZip: String, key: String) -> URLPattern {
    return self.init(string: urlZip, type: .PatternTypeHtmlZip, key: key)
  }
  
}
