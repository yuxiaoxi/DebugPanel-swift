//
//  RussellErrorTests.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2019/2/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import XCTest
@testable import Russell

final class RussellErrorLocalizationTests: XCTestCase {
  
  func testCommonErrors() {
    verifyErrorLocalization(of: RussellError.Common.self)
  }
  
  func testSMSErrors() {
    verifyErrorLocalization(of: RussellError.SMS.self)
  }
  
  func testEmailErrors() {
    verifyErrorLocalization(of: RussellError.Email.self)
  }
  
  func testLoginErrors() {
    verifyErrorLocalization(of: RussellError.LoginSession.self)
  }
  
  func testBindingErrors() {
    verifyErrorLocalization(of: RussellError.Binding.self)
  }
  
  func testSetPasswordErrors() {
    verifyErrorLocalization(of: RussellError.SetPassword.self)
  }
  
  func testUpdatePasswordErrors() {
    verifyErrorLocalization(of: RussellError.UpdatePassword.self)
  }
  
  func testRealNameVerificationErrors() {
    verifyErrorLocalization(of: RussellError.RealNameVerification.self)
  }
  
  private func verifyErrorLocalization<T: RussellLocalizedError>(of type: T.Type) {
    T.allCases.forEach { XCTAssertNotEqual("Russell-unknown", $0.localizedDescription, "\(String(reflecting: $0)) has no localized key") }
  }
}
