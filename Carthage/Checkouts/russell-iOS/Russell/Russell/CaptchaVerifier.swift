//
//  CaptchaVerifier.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/13.
//  Copyright © 2018 LLS. All rights reserved.
//

import GT3Captcha

protocol CaptchaVerifierDelegate: class {
  
  func captchaVerificationSucceeded(_ verifier: CaptchaVerifier, result: CaptchaVerifier.Result)
  
  func captchaVerificationFailed(_ verifier: CaptchaVerifier, error: CaptchaVerifier.Error)
}

// MARK: -

extension CaptchaVerifier {
  
  struct Params: Equatable, Decodable {
    let challenge: String
    let gt: String
  }
  
  struct Result: Decodable {
    
    let challenge: String
    let validate: String
    let seccode: String
    
    enum CodingKeys: String, CodingKey {
      case challenge = "geetest_challenge"
      case validate = "geetest_validate"
      case seccode = "geetest_seccode"
    }
  }
  
  enum Error: Swift.Error {
    case cancelled
    case captchaFailed
  }
}

// MARK: -

/// 对 GeeTest 验证码的封装
class CaptchaVerifier: NSObject {
  
  let id: String
  let params: Params
  required init(id: String, params: Params) {
    self.id = id
    self.params = params
  }
  
  weak var delegate: CaptchaVerifierDelegate?
  
  func start() {
    manager.startGTCaptchaWith(animated: true)
  }
  
  func close() {
    manager.closeGTViewIfIsOpen()
  }
  
  private lazy var manager: GT3CaptchaManager = {
    let manager = GT3CaptchaManager()
    manager.delegate = self
    // `file:///` is just a trick to walk around GT3Captcha param validation for this method, and will never be used in later processes
    manager.configureGTest(params.gt, challenge: params.challenge, success: true, withAPI2: "file:///")
    return manager
  }()
}

// MARK: - GT3CaptchaManagerDelegate

extension CaptchaVerifier: GT3CaptchaManagerDelegate {
  
  @inline(__always)
  private func closeAndFailVerification() {
    manager.closeGTViewIfIsOpen()
    delegate?.captchaVerificationFailed(self, error: .captchaFailed)
  }
  
  func gtCaptcha(_ manager: GT3CaptchaManager!, errorHandler error: GT3Error!) {
    closeAndFailVerification()
  }
  
  func gtCaptcha(_ manager: GT3CaptchaManager!, didReceiveSecondaryCaptchaData data: Data!, response: URLResponse!, error: GT3Error!, decisionHandler: ((GT3SecondaryCaptchaPolicy) -> Void)!) {
    // 不使用默认的二次验证，这个delegate方法不需要处理
  }
  
  func shouldUseDefaultRegisterAPI(_ manager: GT3CaptchaManager!) -> Bool {
    return false
  }
  
  // 不使用默认的二次验证
  func shouldUseDefaultSecondaryValidate(_ manager: GT3CaptchaManager!) -> Bool {
    return false
  }
  
  func gtCaptcha(_ manager: GT3CaptchaManager!, didReceiveCaptchaCode code: String!, result: [AnyHashable: Any]!, message: String!) {
    guard result.map(JSONSerialization.isValidJSONObject) == true,
      let data = try? JSONSerialization.data(withJSONObject: result!, options: []),
      let decodedResult = try? JSONDecoder().decode(Result.self, from: data)
      else {
        return closeAndFailVerification()
    }
    
    manager.closeGTViewIfIsOpen()
    delegate?.captchaVerificationSucceeded(self, result: decodedResult)
  }
  
  func gtCaptchaUserDidCloseGTView(_ manager: GT3CaptchaManager!) {
    delegate?.captchaVerificationFailed(self, error: CaptchaVerifier.Error.cancelled)
  }
}
