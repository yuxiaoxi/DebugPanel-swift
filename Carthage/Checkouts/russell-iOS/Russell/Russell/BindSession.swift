//
//  BindSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

/// 绑定 Session 的抽象 protocol。对应的 `.flow == Flow.bind`。
public protocol BindSession: Session {}

public extension BindSession {
  
  var flow: Flow {
    return .bind
  }
}

public protocol BindSessionDelegate: class {
  
  /// 绑定成功的回调
  func sessionSucceeded(_ session: BindSession)
  
  /// 绑定失败的回调
  /// 错误信息详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2#绑定手机号码)
  /// - Parameters:
  ///   - session: 当前 bind session
  ///   - error: 可能是 `RussellError.Common` `RussellError.BindSession` `RussellError.Response` 中的一种
  func session(_ session: BindSession, failedWithError error: Error)
}
