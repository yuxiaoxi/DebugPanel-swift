//
//  OAuthLoginSessionSpec.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

final class OAuthSessionSpec: QuickSpec {
  
  override func spec() {
    
    describe("code oauth login") {
      
      var networkService: NetworkServiceMock!
      var session: OAuthLoginSession<WechatAuth>!
      var delegate: LoginSessionDelegateMock!
      var tokenStorage: TokenStorage!
      
      beforeEach {
        
        networkService = NetworkServiceMock()
        delegate = LoginSessionDelegateMock()
        tokenStorage = MemoryTokenStorage()
        session = OAuthLoginSession(auth: WechatAuth(appID: "app", code: "code"), poolID: "pool", delegate: delegate, isSignup: false, privacyInfo: PrivacyInfo(hasUserConfirmed: true, action: nil))
      }
      
      context("success") {
        
        beforeEach {
          networkService.json = .loginSuccessResult
          session.run(networkService: networkService, tokenManager: _TokenManagerInternal(tokenStorage: tokenStorage))
        }
        
        it("should call delegate success") {
          expect(delegate.loginResult).toEventuallyNot(beNil())
        }
        
        it("should write token") {
          expect(tokenStorage.token?.accessToken).toEventually(equal("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MzI1MDExNjIsInBvb2xfaWQiOiJ0ZXN0LXBvb2xpZCIsInVzZXJfaWQiOjF9.zlBEl1RA_4StCz86n5lsyk1j-0EDn_8jst0RdjA_Uf4"))
        }
      }
      
      context("fail") {
        beforeEach {
          networkService.json = .empty
          session.run(networkService: networkService, tokenManager: _TokenManagerInternal(tokenStorage: tokenStorage))
        }
        
        it("should call delegate fail") {
          expect(delegate.failureError).toEventuallyNot(beNil())
        }
      }
    }
  }
}
