//
//  SessionRaceSpec.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

final class SessionRaceSpec: QuickSpec {
  
  override func spec() {
    
    describe("session race") {
      
      var service: Russell!
      
      beforeEach {
        let networkService = NetworkServiceMock()
        networkService.json = .loginSuccessResult
        service = Russell(networkService: networkService, poolID: "", deviceID: "ddd", tokenManager: _TokenManagerInternal(tokenStorage: MemoryTokenStorage()), dataTracker: DummyDataTracer(), privacyAction: { _ in })
      }
      
      afterEach {
        service.currentSession?.invalidate()
        service = nil
      }
      
      it("should invalidate previous one") {
        
        let auth = WechatAuth(appID: "111", code: "111")
        
        // session 1 entry first
        let delegate1 = LoginSessionDelegateMock()
        _ = service.startOAuthLoginSession(auth: auth, delegate: delegate1, isSignup: false, hasUserConfirmedPrivacyInfo: true)
        
        // session 2 entry before session 1 finished
        let delegate2 = LoginSessionDelegateMock()
        _ = service.startOAuthLoginSession(auth: auth, delegate: delegate2, isSignup: false, hasUserConfirmedPrivacyInfo: true)
        
        // wait for 0.5 sec
        let expectation = XCTestExpectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 2.0)
        
        // expectations
        expect(delegate2.loginResult).toEventuallyNot(beNil())
        expect(delegate1.loginResult).toEventually(beNil())
      }
    }
  }
}
