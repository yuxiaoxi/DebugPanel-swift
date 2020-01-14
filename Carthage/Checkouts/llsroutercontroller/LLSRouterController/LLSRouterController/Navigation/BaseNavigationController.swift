//
//  BaseNavigationController.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/6.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit


/// 基础导航栏
public class BaseNavigationController: UINavigationController {
  
  var inAnimating: Bool?
  
  
  /// override pushViewController ,添加外部设置的是否有动画参数
  /// - Parameter viewController: 跳转的 vc
  /// - Parameter animated: 是否有动画
  override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if !animated && viewController.urlAction?.animation == NaviAnimationType.NaviAnimationNone {
      // 无动画
      super.pushViewController(viewController, animated: animated)
      inAnimating = false
      return
    }
    inAnimating = true
    super.pushViewController(viewController, animated: animated)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      // 无动画
      self.inAnimating = false
    }
  }
  
  func pushViewController(viewController: UIViewController, withAnimated: Bool) {
    self.pushViewController(viewController, animated: withAnimated)
    if !withAnimated {
      // 无动画
      self.inAnimating = false
    }
  }
  
}
