//
//  KeychainTokenStorageTests.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import XCTest
import Nimble
@testable import Russell

final class KeychainTokenStorageTests: XCTestCase {
  
  private var storage = KeyChainTokenStorage()
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
    storage.token = nil
  }
  
  func testInsert() {
    let token = Token(accessToken: "a", refreshToken: "r", expiringDate: .distantFuture)
    storage.token = token
    expect(self.storage.token) == token
  }
  
  func testUpdate() {
    let token = Token(accessToken: "a", refreshToken: "r", expiringDate: .distantFuture)
    storage.token = token
    
    let token2 = Token(accessToken: "b", refreshToken: "r2", expiringDate: .distantFuture)
    storage.token = token2
    expect(self.storage.token) == token2
  }
  
  func testDelete() {
    let token = Token(accessToken: "a", refreshToken: "r", expiringDate: .distantFuture)
    storage.token = token
    
    storage.token = nil
    expect(self.storage.token).to(beNil())
  }
}
