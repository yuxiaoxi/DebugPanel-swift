//
//  DebugUtils.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/9/3.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import Foundation

/// 判断是否是留海屏
public func isIphoneX() -> Bool {
  
  var iSIPhoneX = false
  if #available(iOS 11.0, *) {
    iSIPhoneX = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0 > 0.0
  }
  return iSIPhoneX
}

/// 获取屏幕宽度
public func getDBScreenWidth() -> CGFloat {
  let screenSize: CGSize = UIScreen.main.bounds.size
  return screenSize.width
}

/// 获取屏幕高度
public func getDBScreenHeight() -> CGFloat {
  let screenSize: CGSize = UIScreen.main.bounds.size
  return screenSize.height
}

extension UIView {
  /// 将当前视图转为UIImage
  public func asImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { rendererContext in
      layer.render(in: rendererContext.cgContext)
    }
  }
}

extension UIColor {
  /// string to UIColor
  /// - Parameter hexString: color string
  public static func colorWithHexString(_ hexString: String) -> UIColor {
    let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    let scanner = Scanner(string: hexString)
    
    if hexString.hasPrefix("#") {
      scanner.scanLocation = 1
    }
    
    if hexString.hasPrefix("0X") {
      scanner.scanLocation = 2
    }
    
    var color: UInt32 = 0
    scanner.scanHexInt32(&color)
    
    let mask = 0x000000FF
    let r = Int(color >> 16) & mask
    let g = Int(color >> 8) & mask
    let b = Int(color) & mask
    
    let red   = CGFloat(r) / 255.0
    let green = CGFloat(g) / 255.0
    let blue  = CGFloat(b) / 255.0
    
    return UIColor.init(red: red, green: green, blue: blue, alpha: 1)
  }
}

extension UIViewController {
  
  /// 获取当前可见的 NavigationController
  public static var visibleNavigationController: UINavigationController? {
    return UIApplication.shared.keyWindow?.rootViewController?.visibleNavigationViewController()
  }
  
  func visibleNavigationViewController() -> UINavigationController? {
    if let presentedViewController = self.presentedViewController {
      return presentedViewController.visibleNavigationViewController()
    } else if let tabController = self as? UITabBarController {
      return  tabController.selectedViewController?.visibleNavigationViewController()
    } else if let navigationController = self as? UINavigationController {
      return navigationController
    }
    return nil
  }
  
}
