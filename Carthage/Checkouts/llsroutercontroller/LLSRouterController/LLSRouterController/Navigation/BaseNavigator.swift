//
//  BaseNavigator.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/6.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

/// 路由控制器的基础类
public class BaseNavigator: NSObject {
  
  /// keywindow 的主导航栏
  public var mainNavigationController: BaseNavigationController?
  
  /// 当前 app 的 scheme, 如：lls
  public var handleableURLScheme: String?
  
  /// VC 的路由配置文件名
  public var fileNamesOfURLMapping: String?
  // url actions waiting for handle
  var urlActionWaitingList: [URLAction]?
  var urlMapping: [String: URLPattern]? // host与NVURLPattern的映射关系，host为key，NVURLPattern为value
  var animating: Bool? {
    return self.mainNavigationController?.inAnimating
  }
  
  override init() {
    self.urlActionWaitingList = [URLAction]()
    self.handleableURLScheme = "lls"
  }
  
  func canOpenInBlockMode() -> Bool {
    return !self.inBlockMode()
  }
}

// MARK: public methods
public extension BaseNavigator {
  
  /// 当前主导航栏当前是否有需要被 presented的 VC
  func inBlockMode() -> Bool {
    return self.mainNavigationController?.presentedViewController != nil || self.animating ?? false
  }
  
  /// 通过 urlAction 匹配他的目标 VC 类
  /// - Parameter urlAction: urlAction
  func matchClassWithURLAction(urlAction: URLAction) -> AnyClass? {
    return urlAction.urlPattern?.targetClass
  }
  
  /// 从路由配置文件中加载 scheme 以及对应的 VC
  func loadPattern() -> [String: URLPattern]? {
    if urlMapping != nil {
      urlMapping?.removeAll()
    } else {
      urlMapping = [String: URLPattern]()
    }
    guard fileNamesOfURLMapping != nil else {
      return nil
    }
    
    let fileName = fileNamesOfURLMapping!
    let path = Bundle.main.path(forResource: fileName, ofType: nil) ?? ""
    do {
      let content = try String.init(contentsOfFile: path, encoding: .utf8)
      guard !content.isEmpty else {
        return nil
      }
      
      let earchLine = content.components(separatedBy: "\n")
      for aStr in earchLine {
        if aStr.isEmpty { // 空行
          continue
        }
        var lineString = aStr.replacingOccurrences(of: " ", with: "")
        if lineString.isEmpty { // 空行
          continue
        }
        if lineString.hasPrefix("#") { // 注释行
          continue
        }
        if lineString.contains("#") {
          // 后面有注释，需要去掉注释内容
          lineString = String(lineString.split(separator: "#")[0])
        }
        lineString = lineString.replacingOccurrences(of: "\t", with: "")
        if lineString.contains(":") {
          let kv = lineString.split(separator: ":")
          if kv.count == 2 {
            let host = kv[0].lowercased()
            let className = kv[1].replacingOccurrences(of: " ", with: "")
            if host.count < 1 {
              continue
            }
            if className.count < 1 {
              continue
            }
            if NSClassFromString(className) == nil {
              continue
            }
            if urlMapping?[host] != nil {
              continue
            }
            urlMapping?[host] = URLPattern.patternWithClass(className: className, key: host)
          }
        }
        
      }
    } catch {
      return nil
    }
    
    return urlMapping
  }
  
  /// 通过 scheme 方式弹出 VC
  /// - Parameter scheme: 需要被弹出的 VC 的 scheme
  func popByScheme(scheme: String) -> Bool {
    return self.popBySchemes(schemeArray: [scheme])
  }
  
  /// 通过 scheme 方式弹出 一组 VC
  /// - Parameter schemeArray: scheme 组
  func popBySchemes(schemeArray: [String]) -> Bool {
    if schemeArray.isEmpty || mainNavigationController == nil {
      return false
    }
    if self.inBlockMode() {
      return false
    }
    if self.mainNavigationController?.viewControllers.isEmpty ?? true {
      return false
    }
    let vcCount = self.mainNavigationController?.viewControllers.count ?? 0
    var i = vcCount - 1
    while i >= 0 {
      for scheme in schemeArray {
        let pattern: URLPattern? = urlMapping?[scheme.lowercased()]
        guard pattern != nil else {
          continue
        }
        let classType: AnyClass = pattern!.targetClass!
        if self.mainNavigationController?.viewControllers[i].isKind(of: classType) ?? false {
          self.mainNavigationController?.popToViewController((self.mainNavigationController?.viewControllers[i])!, animated: true)
        }
      }
      
      i -= 1
    }
    return false
  }
  
  /// 判断当前页面是否从某个特定的页面跳转而来
  /// - Parameter scheme: 某个页面的scheme
  /// @return 是否从这个页面跳转而来
  func isFromScheme(scheme: String) -> Bool {
    return false
  }
}

// MARK: Subclass should implement and call
extension BaseNavigator {
  
  public func shouldOpenURLAction(urlAction: URLAction) -> Bool {
    return true
  }
  
  public func willOpenExternal(urlAction: URLAction) -> Void {
    
  }
  
  public func onMatchUnhandledURLAction(urlAction: URLAction) -> Void {
    
  }
  
  public func onMatchViewController(controller: UIViewController, urlAction: URLAction) -> Void {
    
  }
  
}

// MARK: private methods
extension BaseNavigator {
  
  func filterCleanStr(aStr: String) -> String {
    
    return ""
  }
  
  func matchPatternWithURLAction(urlAction: URLAction) -> URLPattern? {
    if urlAction.url.host?.isEmpty ?? false {
      return nil
    }
    return urlMapping?[urlAction.url.host!.lowercased()]
  }
  
  func obtainControllerWithPattern(pattern: URLPattern) -> UIViewController? {
    if pattern.targetClass == nil {
      return nil
    }
    let anyclass: AnyClass = pattern.targetClass!
    let className:String = NSStringFromClass(anyclass)
    
    if let classType = NSClassFromString(className) as? UIViewController.Type {
      return classType.init()
    }
    
    return nil
  }
  
  func obtainTargetControllerAndCheckURLAction(urlAction: URLAction, open: Bool) -> UIViewController? {
    
    guard mainNavigationController != nil else {
      return nil
    }
    
    guard self.shouldOpenURLAction(urlAction: urlAction) else {
      return nil
    }
    
    let url = urlAction.url
    let scheme = url.scheme
    let schemeIsSame = self.handleableURLScheme?.caseInsensitiveCompare(scheme!) != ComparisonResult.orderedSame
    // check unhandleable url scheme
    if urlAction.openExternal || schemeIsSame {
      self.willOpenExternal(urlAction: urlAction)
      UIApplication.shared.open(urlAction.url.absoluteURL!, options: [:], completionHandler: nil)
      return nil
    }
    // check unhandled url host
    let pattern = self.matchPatternWithURLAction(urlAction: urlAction)
    if pattern == nil {
      self.onMatchUnhandledURLAction(urlAction: urlAction)
      return nil
    }
    urlAction.urlPattern = pattern
    // check unhandled class
    let controller = self.obtainControllerWithPattern(pattern: pattern!)
    if controller != nil {
      self.onMatchViewController(controller: controller!, urlAction: urlAction)
    }
    return controller
  }
  
  func handleOpenURLAction(urlAction: URLAction) -> UIViewController? {
    return self.handleOpenURLAction(urlAction: urlAction, open: true)
  }
  
  func handleOpenURLAction(urlAction: URLAction, open: Bool) -> UIViewController? {
    let controller = self.obtainTargetControllerAndCheckURLAction(urlAction: urlAction, open: open)
    guard controller != nil else {
      return nil
    }
    
    if open {
      self.openViewController(controller: controller!, urlAction: urlAction)
    } else {
      controller?.urlAction = urlAction
      _ = self.commonHandleURLAction(urlAction: urlAction, controller: controller!)
    }
    return controller
  }
  
  func openViewController(controller: UIViewController, urlAction: URLAction) -> Void {
    controller.urlAction = urlAction
    
    guard self.commonHandleURLAction(urlAction: urlAction, controller: controller) else {
      return
    }
    self.pushViewController(controller: controller, urlAction: urlAction)
  }
  
  func commonHandleURLAction(urlAction: URLAction, controller: UIViewController) -> Bool {
    
//    if controller.responds(to: #selector()) {
      return controller.handleWithURLAction(urlAction: urlAction)
//    }
  }
  
  func pushViewController(controller: UIViewController, urlAction: URLAction) -> Void {
    // 如果是处理堵塞的页面，一次性压入所有页面，只有最后一个页面使用动画
    var animation = NaviAnimationType.NaviAnimationNone
    if urlActionWaitingList?.isEmpty ?? false {
      animation = urlAction.animation
    }
    self.mainNavigationController?.pushViewController(controller, animated: animation != NaviAnimationType.NaviAnimationNone)
  }
  
}
