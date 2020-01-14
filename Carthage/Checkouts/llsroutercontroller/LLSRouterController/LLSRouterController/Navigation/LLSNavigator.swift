//
//  LLSNavigator.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/25.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

public protocol LLSNavigatorDelegate {
  
  func shouldOpenURLAction(urlAction: URLAction) -> Bool
  
  func willOpenExternal(urlAction: URLAction) -> Void
  
  func onMatchUnhandledURLAction(urlAction: URLAction) -> Void
  
  func onMatchViewController(controller: UIViewController, urlAction: URLAction) -> Void
}

public class LLSNavigator: BaseNavigator {
  
  public var delegate: LLSNavigatorDelegate?
  
  private static let gNavigator: LLSNavigator = LLSNavigator()
  
  private override init() {}

}

// MAKR: public methods
public extension LLSNavigator {
  
  static var navigator: LLSNavigator {
    get {
      return gNavigator
    }
  }
  
  func configMainNavigationViewController(mainNavigationViewController: BaseNavigationController) {
    self.mainNavigationController = mainNavigationViewController
  }
  
  func configHandleableUrlScheme(scheme: String) {
    self.handleableURLScheme = scheme
  }
  
  func configFileNameOfURLMapping(fileName: String) {
    self.fileNamesOfURLMapping = fileName
    _ = self.loadPattern()
  }
  
  func openURL(url: NSURL) -> UIViewController? {
    return self.openURLAction(urlAction: URLAction.actionWithURL(url: url)!)
  }
  
  func openURLString(urlString: String) -> UIViewController? {
    return self.openURLAction(urlAction: URLAction.actionWithURLString(urlString: urlString)!)
  }
  
  func openURLAction(urlAction: URLAction) -> UIViewController? {
    guard urlAction.isKind(of: URLAction.self) else {
        return nil
      }
      
    return self.handleOpenURLAction(urlAction: urlAction)
  }
}

// MARK: navigation extention of UIViewController
public extension UIViewController {
  
  func openURLHost(urlHost: String) -> UIViewController? {
    let scheme = LLSNavigator.navigator.handleableURLScheme
    if scheme == nil || urlHost.count < 1 {
      return nil
    }
    return LLSNavigator.navigator.openURLString(urlString: "\(String(describing: scheme))://\(urlHost)")
  }
  
  func openURL(url: NSURL) -> UIViewController? {
    return LLSNavigator.navigator.openURL(url: url)
  }
  
  func openURLString(urlString: String) -> UIViewController? {
    return LLSNavigator.navigator.openURLString(urlString: urlString)
  }
  
  func openURLAction(urlAction: URLAction) -> UIViewController? {
    return LLSNavigator.navigator.openURLAction(urlAction: urlAction)
  }
  
}
