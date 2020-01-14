//
//  SMSLoginSessionSpec.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

final class SMSLoginSessionSpec: QuickSpec {
  
  override func spec() {
    
    describe("SMS login session") {
      
      var networkService: NetworkServiceMock!
      var worker: SMSLoginFlowWorker!
      var session: _SMSLoginSessionInternal!
      var delegate: SMSLoginSessionDelegateMock!
      var tokenStorage: TokenStorage!
      
      beforeEach {
        
        networkService = NetworkServiceMock()
        delegate = SMSLoginSessionDelegateMock()
        tokenStorage = MemoryTokenStorage()
        worker = SMSLoginFlowWorker(poolID: "", networkService: networkService)
        session = _SMSLoginSessionInternal(delegate: delegate, flowWorker: worker, tokenManager: _TokenManagerInternal(tokenStorage: tokenStorage), networkService: networkService, isSignup: false)
      }
      
      context("enter mobile") {
        
        it("should switch to login state") {
          session.login(mobile: "mobile")
          
          expect(worker.state) == .sendVerificationCode(account: "mobile")
        }
        
        context("with sms challenge response") {
          
          beforeEach {
            networkService.json = .smsChallenge
            session.login(mobile: "mobile")
          }
          
          it("should switch to sms challenge state") {
            expect(worker.state).toEventually(equal(.verificationCodeChallenge(account: "mobile", sessionID: "sms-session-ID")))
          }
          
          it("should try to get sms code from delegate") {
            expect(delegate.requiresSMSCounter).toEventually(beGreaterThan(0))
          }
        }
        
        context("with captcha challenge response") {
          
          var captchaVerifier: CaptchaVerifierMock!
          
          beforeEach {
            captchaVerifier = CaptchaVerifierMock(id: "captcha-session-ID", params: CaptchaVerifier.Params(challenge: "", gt: ""))
          }
          
          func setup() {
            networkService.json = .captchaChallenge
            
            worker.captchaVerifierGenerator = { _, _ in captchaVerifier }
            session.login(mobile: "mobile")
          }
          
          it("should switch to captcha verification state") {
            setup()
            expect(worker.state).toEventually(equal(.geeTestChallenge(account: "mobile", captchaID: "captcha-session-ID", param: CaptchaVerifier.Params(challenge: "ch", gt: "gt"))))
          }
          
          it("should show captcha verifier") {
            setup()
            expect(captchaVerifier.isShowing).toEventually(beTrue())
          }
          
          it("should request SMS code if succeeded") {
            captchaVerifier.isSuccessful = true
            setup()
            networkService.json = .smsChallenge
            
            expect(worker.state).toEventually(equal(.verificationCodeChallenge(account: "mobile", sessionID: "sms-session-ID")), timeout: 2)
          }
          
          it("should send error if failed at step 1") {
            setup()
            captchaVerifier.isSuccessful = false
            
            expect(delegate.failureError).toEventuallyNot(beNil())
          }
          
          it("should send error if failed at step 2") {
            setup()
            captchaVerifier.isSuccessful = true
            networkService.json = .empty
            
            expect(delegate.failureError).toEventuallyNot(beNil(), timeout: 2)
          }
        }
        
        context("with empty response") {
          
          beforeEach {
            networkService.json = .empty
            session.login(mobile: "mobile")
          }
          
          it("should switch to sendSMS state") {
            expect(worker.state).toEventually(equal(.sendVerificationCode(account: "mobile")))
          }
          
          it("should notify delegate error") {
            expect(delegate.failureError).toEventuallyNot(beNil())
          }
        }
      }
      
      context("enter SMS code") {
        
        beforeEach {
          worker.state = .verificationCodeChallenge(account: "mobile", sessionID: "session1")
          networkService.json = .loginSuccessResult
        }
        
        it("should callback result if succeeded") {
          session.verify(code: "code")
          expect(delegate.loginResult).toEventuallyNot(beNil())
          expect(tokenStorage.token?.accessToken).toEventually(equal("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MzI1MDExNjIsInBvb2xfaWQiOiJ0ZXN0LXBvb2xpZCIsInVzZXJfaWQiOjF9.zlBEl1RA_4StCz86n5lsyk1j-0EDn_8jst0RdjA_Uf4"))
        }
        
        it("should send error if failed") {
          networkService.json = .empty
          session.verify(code: "code")
          expect(delegate.failureError).toEventuallyNot(beNil())
        }
      }
    }
  }
}
