//
//  NetworkLoggerPluginTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import Quicksilver

class NetworkLoggerPluginTests: XCTestCase {
  
  struct TestError: Error {}
  
  struct TestTargetType: TargetType {
    
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
    
  }
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testWillSendRequest() {
    // Given
    let exception = expectation(description: "testWillSendRequest")

    let plugin = NetworkLoggerPlugin(cURL: false, output: { (_) in
      exception.fulfill()
    }, requestDataFormatter: nil, responseDataFormatter: nil)
    
    let targetBasic = TestTargetType()
    
    let url = URL(string: "https://www.apple.com")!
    let request = URLRequest(url: url)
    
    // When
    plugin.willSend(request, target: targetBasic)
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }
  
  func testWillSendRequestWithCurl() {
    // Given
    let exception = expectation(description: "testWillSendRequest")
    
    let plugin = NetworkLoggerPlugin(cURL: true, output: { (_) in
      exception.fulfill()
    }, requestDataFormatter: nil, responseDataFormatter: nil)
    
    let targetBasic = TestTargetType()
    
    let url = URL(string: "https://www.apple.com")!
    let request = URLRequest(url: url)
    
    // When
    plugin.willSend(request, target: targetBasic)
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }
  
  func testDidReceiveWithSuccessResponse() {
    // Given
    let exception = expectation(description: "testWillSendRequest")
    let plugin = NetworkLoggerPlugin(cURL: true, output: { (_) in
      exception.fulfill()
    }, requestDataFormatter: nil, responseDataFormatter: nil)
    let response = Response(statusCode: 200, data: Data())
    let result = Result<Response, QuicksilverError>.success(response)
    
    let targetBasic = TestTargetType()

    // When
    plugin.didReceive(result, target: targetBasic)
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }

  func testDidReceiveWithFailedResponse() {
    // Given
    let exception = expectation(description: "testWillSendRequest")
    let plugin = NetworkLoggerPlugin(cURL: true, output: { (_) in
      exception.fulfill()
    }, requestDataFormatter: nil, responseDataFormatter: nil)
    let result = Result<Response, QuicksilverError>.failure(QuicksilverError.underlying(TestError(), nil))
    
    let targetBasic = TestTargetType()
    
    // When
    plugin.didReceive(result, target: targetBasic)
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }

}
