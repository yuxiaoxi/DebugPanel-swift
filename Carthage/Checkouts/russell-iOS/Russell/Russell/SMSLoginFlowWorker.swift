//
//  SMSLoginFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class SMSLoginFlowWorker: VerificationCodeFlowWorker<AuthOrConfirmToRegisterChallenge> {
  
  override var authFlow: String {
    return "SMS_CODE"
  }
  
  override var kind: Kind {
    return .sms
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    
    let params: [String: Any] = [
      "challengeType": "SMS_CODE",
      "session": sessionID,
      "poolId": poolID,
      "smsResp": [
        "mobile": account,
        "code": code
      ]
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.loginSessionErrorMapping]
  }
}
