//
//  URLAction.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/6.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

public enum NaviAnimationType: Int {
  case NaviAnimationNone = -1 // 没有动画
  case NaviAnimationPush = 0 // 标准的导航压入动画
}

public class URLAction: NSObject {
  
  /**
   需要导航到的url地址
   */
  public var url: NSURL
  
  /**
   导航动画
   @param animation: 动画类型，默认为NVNaviAnimationPush
   */
  public var animation: NaviAnimationType
  
  /**
   所有的参数构建成query
   */
  public var query: String = ""
  
  /**
   如果url为http url，则会询问是否在外部打开
   默认为NO
   */
  public var openExternal: Bool
  
  /**
   对应的NVURLPattern, online url mapping可能会修改pattern，所以需要将pattern粘贴在urlAction中
   */
  public var urlPattern: URLPattern?
  
  var params: [String: Any]
  
  
  init(url: NSURL) {
    self.url = url
    self.animation = .NaviAnimationPush
    self.openExternal = false
    let dict = url.parseQuery()
    params = [String: String]()
    for key in dict.keys {
      params[key.lowercased()] = dict[key]
    }
  }
  
  required convenience init(u: NSURL) {
    self.init(url: u)
  }
  
  required convenience init(urlString: String) {
    self.init(url: NSURL.init(string: urlString)!)
  }
  
  required convenience init(host: String) {
    let scheme = "" // like lls
    self.init(urlString: "\(scheme):\(host)")
  }
  
  func description() -> String? {
    
    guard !params.isEmpty else {
      return url.absoluteString
    }
    
    let paramsDesc: NSMutableArray = NSMutableArray(capacity: params.count)
    for key in params.keys {
      let value: Any? = params[key]
      paramsDesc.add("\(String(describing: key.lowercased))=\(String(describing: value))")
    }
    let urlString: String = url.absoluteString ?? ""
    if urlString.contains("?") {
      return urlString.split(separator: "?")[1] + "?\(paramsDesc.componentsJoined(by: "&"))"
    }
    return urlString + "?\(paramsDesc.componentsJoined(by: "&"))"
  }
}

// MARK: public Methods
extension URLAction {
  
  public static func actionWithURL(url: NSURL) -> URLAction? {
    return self.init(u: url)
  }
  
  public static func actionWithURLString(urlString: String) -> URLAction? {
    return self.init(urlString: urlString)
  }
  
  public static func actionWithHost(host: String) -> URLAction? {
    return self.init(host: host)
  }
  
  public func setValueInParam(value: Any, key: String) -> Void {
    
    params[key.lowercased()] = value
  }
  
  public func integerForKey(key: String) -> Int {
    
    if let value = params[key.lowercased()] as? Int {
      return value
    }
    return 0
  }
  
  public func doubleForKey(key: String) -> Double {
    
    if let value = params[key.lowercased()] as? Double {
      return value
    }
    return 0.0
  }
  
  public func stringForKey(key: String) -> String {
    
    if let value = params[key.lowercased()] as? String {
      return value
    }
    return ""
  }
  
  public func boolForKey(key: String) -> Bool {
    
    if let value = params[key.lowercased()] as? Bool {
      return value
    }
    return false
  }
  
  public func objectForKey(key: String) -> AnyObject {
    
    return params[key.lowercased()] as AnyObject
  }
  
  public func anyObjectForKey(key: String) -> Any {
    
    return params[key.lowercased()] as Any
  }
  
  public func removeObjectForKey(key: String) -> Void {
    
    params.removeValue(forKey: key)
  }
  
  public func addEntriesFromDictionary(otherDict: [String: Any]) -> Void {
    
    guard !otherDict.isEmpty else {
      return
    }
    params.merge(otherDict) {
      (current, _) in current
    }
  }
  
  public func addParamsFromURLAction(otherURLAction: URLAction) -> Void {
    
    let otherDict = otherURLAction.queryDictionary()
    self.addEntriesFromDictionary(otherDict: otherDict)
  }
  
  public func queryDictionary() -> [String: Any] {
    
    return params
  }
  
}

// MARK: URLAction exstension of UIViewController
public extension UIViewController {
  
  private struct AssociatedKey {
    static var urlActionKey = "UIViewControllerURLAction"
  }
  
  /// 通过运行时特性——关联属性来给extension 添加存储属性，https://blog.csdn.net/understand_XZ/article/details/89673078
  var urlAction: URLAction? {
    get {
      // return objc_getAssociatedObject(self, &AssociatedKey.urlActionKey) as? URLAction
      // &AssociatedKey.urlActionKey 会crash找不到地址，需要将AssociatedKey.urlActionKey整个括号包起来再取地址
      return objc_getAssociatedObject(self, &(AssociatedKey.urlActionKey)) as? URLAction
    }
    set {
      objc_setAssociatedObject(self, &(AssociatedKey.urlActionKey), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
}
