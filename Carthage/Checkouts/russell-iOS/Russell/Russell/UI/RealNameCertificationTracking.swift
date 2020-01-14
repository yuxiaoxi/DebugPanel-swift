//
//  RealNameCertificationTracking.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/13.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

struct BindMobileTracking {
  var source: Source
  var currentMobileStatus: CurrentMobileStatus
  
  var parameters: [String: Any] {
    return [
      "source": source.rawValue,
      "currentStatus": currentMobileStatus.rawValue
    ]
  }
}

extension BindMobileTracking {
  enum Source: Int {
    /// 新注册
    case newRegister
    /// 已注册用户登录
    case signIn
    /// 需要确认隐私协议
    case bindingWithPolicy
    /// 到期提醒
    case expirationReminder
    /// 到期更换
    case expiration
    /// 个人中心
    case userCenter
    /// 一键绑定失败，页面重新跳转到短信验证码
    /// 6，7是后端打点专属使用 https://wiki.liulishuo.work/pages/viewpage.action?pageId=62506365
    case oneBindingFailed = 8
    /// 一键绑定 - 绑定其他号码
    case oneBindingSwitch = 9
  }
}

extension BindMobileTracking {
  
  enum CurrentMobileStatus: Int {
    case none
    case weak
    case strong
  }
}

enum TargetMobileStatusTracking: Int {
  case weak
  case strong
  case oauthBoundable
}
