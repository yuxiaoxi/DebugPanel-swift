//
//  CodeVerificationSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public enum CodeVerificationType {
  case sms
  case email
}

public protocol CodeVerificationSession: class {
  
  /// 验证码类型
  var codeType: CodeVerificationType { get }
  
  /// 校验验证码。
  ///
  /// - Parameters:
  ///   - code: 用户输入的验证码
  func verify(code: String)
  
  /// 重新发送验证码。仅在 Session 创建之后，invalidate 之前有效，否则不会发生任何事情。
  func resendVerificationMessage()
}

public protocol CodeVerificationSessionDelegate: class {
  
  /// 当前登录流程需要用户输入已收到的短信/Email验证码。
  ///
  /// - Parameters:
  ///   - session: 发起回调的 session 对象
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession)
}
