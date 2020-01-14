//
//  AccessTokenPluginTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import Quicksilver

class AccessTokenPluginTests: XCTestCase {
  
  struct TestTargetType: TargetType, AccessTokenAuthorizable {
    
    var headers: [String: String]? {
      return nil
    }

    /// Default value is `.successCodes`.
    var validation: ValidationType {
      return .successCodes
    }
    /// Default value is nil.
    var parameters: [String: Any]? {
      return nil
    }
    
    var fullRequestURL: URL {
      return URL(string: "https://www.apple.com")!
    }
    
    var priority: Float {
      return 0.5
    }

    /// The HTTP method used in the request.
    var method: HTTPMethod {
      return .get
    }
    
    let authorizationType: AuthorizationType
  }
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testPrepareRequest() {
    // Given
    let accessTokenPlugin = AccessTokenPlugin(tokenClosure: "1234")
    let url = URL(string: "https://www.apple.com")!
    let request = URLRequest(url: url)
    let targetBasic = TestTargetType(authorizationType: .basic)
    let targetBearer = TestTargetType(authorizationType: .bearer)
    let targetNone = TestTargetType(authorizationType: .none)

    // When
    let targetBasicFinalRequest = accessTokenPlugin.prepare(request, target: targetBasic)
    let targetBearerFinalRequest = accessTokenPlugin.prepare(request, target: targetBearer)
    let targetNoneFinalRequest = accessTokenPlugin.prepare(request, target: targetNone)
    
    // Then
    let basicAuthorizationValue = targetBasicFinalRequest.value(forHTTPHeaderField: "Authorization")!
    XCTAssert(basicAuthorizationValue == "Basic 1234", "Authorization error")
    
    let bearerAuthorizationValue = targetBearerFinalRequest.value(forHTTPHeaderField: "Authorization")!
    XCTAssert(bearerAuthorizationValue == "Bearer 1234", "Authorization error")
    
    let noneAuthorizationValue = targetNoneFinalRequest.value(forHTTPHeaderField: "Authorization")
    XCTAssert(noneAuthorizationValue == nil, "Authorization error")
  }

}
