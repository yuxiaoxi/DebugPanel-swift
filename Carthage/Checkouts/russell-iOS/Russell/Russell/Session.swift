//
//  Session.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// Session 对应的流程
///
/// - login: 登录
/// - refreshToken: 更新 Token
/// - logout: 登出
/// - bind: 绑定
/// - resetPassword: 重置密码
public enum Flow {
  
  case login
  
  case refreshToken
  
  case logout
  
  case bind
  
  case resetPassword
}

/// Russell 中的任意一个会话。
/// - Note: Russell 被设计成一个 Token 相关的会话管理中心，任何一类会影响到账户状态变化的操作(登录/更新 Token/登出/绑定手机 等)都被归为一个 Session。
/// - Note: Session 之间具有互斥性。启动任何一个新的 Session 将会 invalidate 当前正在进行的 Session。
public protocol Session: class {
  
  /// 当前 Session 对应的流程
  var flow: Flow { get }
  
  // 废弃该 Session
  func invalidate()
}
