//
//  RealNameCertificationSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

public struct PrivacyInfo {
  
  /// 用户是否已经同意隐私政策
  public let hasUserConfirmed: Bool
  /// 隐私政策跳转回调。如果用户尚未同意隐私政策，则该回调不可以为空
  public let action: ((_ container: UINavigationController) -> Void)?
  
  /// PrivacyInfo
  ///
  /// - Parameters:
  ///   - hasUserConfirmed: 用户是否已经同意隐私政策
  ///   - action: 隐私政策跳转回调。如果用户尚未同意隐私政策，则该回调不可以为空
  public init(hasUserConfirmed: Bool, action: ((_ container: UINavigationController) -> Void)?) {
    self.hasUserConfirmed = hasUserConfirmed
    self.action = action
  }
}

public protocol RealNameCertificationSessionDelegate: class {
  
  /// 需要进入实名认证流程
  ///
  /// - Parameter session: 触发实名认证的 Session
  /// - Returns: 用于展示实名认证界面的容器
  func sessionRequiresRealNameCertification(_ session: Session) -> Russell.UI.Container
  
  /// 是否需要自动关闭实名认证 UI
  ///
  /// - Returns: 默认实现返回 true
  func sessionShouldAutomaticallyDismissRealNameCertificationUI(_ session: Session) -> Bool
  
  /// 是否需要对一键登录 SDK 进行二次初始化
  /// - Parameter completion: 回调
  func sessionShouldBinderInitFirst(completion: (Bool) -> Void)
}

public extension RealNameCertificationSessionDelegate {
  
  func sessionShouldAutomaticallyDismissRealNameCertificationUI(_ session: Session) -> Bool {
    return true
  }
  
  func sessionShouldBinderInitFirst(completion: (Bool) -> Void) {
    completion(false)
    Logger.info("One Key Binder retry setup sdk")
  }
  
}
