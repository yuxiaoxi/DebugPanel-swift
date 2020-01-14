//
//  CaptchaVerifierMock.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

@testable import Russell

final class CaptchaVerifierMock: CaptchaVerifier {
  
  var isSuccessful: Bool?
  
  private(set) var isShowing = false
  override func start() {
    isShowing = true
    DispatchQueue.main.async {
      guard let isSuccessful = self.isSuccessful else {
        return
      }
      
      self.isShowing = false
      
      if isSuccessful {
        self.delegate?.captchaVerificationSucceeded(self, result: CaptchaVerifier.Result(challenge: "", validate: "", seccode: ""))
      } else {
        self.delegate?.captchaVerificationFailed(self, error: .captchaFailed)
      }
    }
  }
}
