//
//  VerificationCodeSessionCache.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/9/6.
//  Copyright © 2019 LLS. All rights reserved.
//
// 缓存短信/邮箱验证码 Session 以优化用户体验: https://jira.liulishuo.work/browse/LLSPAY-378

import Foundation

final class VerificationCodeSessionCache {
  
  struct Session {
    private let expireDate: Date
    let id: String
    let info: MobileVerificationInfo?
    
    init(id: String, info: MobileVerificationInfo?) {
      self.expireDate = Date(timeIntervalSinceNow: 61)  // Use 61 instead of 60 to avoid networking gap
      self.id = id
      self.info = info
    }
    
    var timeout: Int {
      return Int(ceil(expireDate.timeIntervalSinceNow))
    }
    
    var isValid: Bool {
      return expireDate.timeIntervalSinceNow > 0
    }
  }
  
  private var storage: [String: Session] = [:]
  
  func session(for account: String) -> Session? {
    guard let session = storage[account] else {
      return nil
    }
    
    if session.isValid {
      return session
    } else {
      storage[account] = nil
      return nil
    }
  }
  
  func updateSession(_ session: String, info: MobileVerificationInfo?, for account: String) {
    storage[account] = Session(id: session, info: info)
  }
}
