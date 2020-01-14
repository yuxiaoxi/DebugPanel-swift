//
//  LogoutTests.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2019/3/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import XCTest
import Nimble
@testable import Russell

final class LogoutTests: XCTestCase {
  
  private var russell: Russell?
  private var tokenStorage: TokenStorage?
  
  override func setUp() {
    super.setUp()
    let tokenStorage = MemoryTokenStorage()
    tokenStorage.token = Token(accessToken: "", refreshToken: "", expiringDate: Date())
    russell = Russell(networkService: NetworkServiceMock(), poolID: "", deviceID: "ddd", tokenManager: _TokenManagerInternal(tokenStorage: tokenStorage), dataTracker: DummyDataTracer(), privacyAction: { _ in })
    self.tokenStorage = tokenStorage
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testLogout() {
    
    russell?.logout()
    expect(self.tokenStorage?.token).toEventually(beNil())
  }
}
