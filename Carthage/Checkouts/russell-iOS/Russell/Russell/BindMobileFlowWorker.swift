//
//  BindMobileFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class BindMobileFlowWorker: VerificationCodeFlowWorker<Empty> {
  
  override var authFlow: String {
    return "BIND_MOBILE"
  }
  
  override var kind: Kind {
    return .sms
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    let params: [String: Any] = [
      "poolId": poolID,
      "mobile": account,
      "code": code,
      "session": sessionID
    ]
    
    return API(method: .post, path: "/api/v2/bind_mobile", body: params)
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.bindingSessionErrorMapping]
  }
}
