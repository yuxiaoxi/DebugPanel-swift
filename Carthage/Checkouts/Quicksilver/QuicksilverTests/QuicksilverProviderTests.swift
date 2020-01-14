//
//  QuicksilverProviderTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import AFNetworkingPrivate
@testable import Quicksilver

class QuicksilverProviderTests: XCTestCase {
  
  class TestDataTargetType: DataTargetType {
    
    var baseURL: URL {
      return URL(string: "https://www.liulishuo.com/v1/")!
    }
    
    var path: String {
      return "test"
    }
    
    var method: HTTPMethod {
      return .get
    }
    
    var sampleResponse: SampleResponseClosure? {
      return {
        return SampleResponse.networkResponse(200, Data())
      }
    }
  }
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testRequest() {
    // Given
    let exception = expectation(description: "testRequestNormal")
    let logPluginException = expectation(description: "testRequestNormalForPlugin")
    
    let configuration = QuicksilverURLSessionConfiguration()
    var logCount = 6
    let logPlugin = NetworkLoggerPlugin(cURL: false, output: { (_) in
      logCount -= 1
      if logCount == 0 {
        logPluginException.fulfill()
      }
    })
    let provider = QuicksilverProvider(configuration: configuration, plugins: [logPlugin], callbackQueue: nil)
    let target = TestDataTargetType()
    
    stub(condition: { (request) -> Bool in
      if let url = request.url, url.absoluteString.contains("https://www.liulishuo.com/") {
        return true
      } else {
        return false
      }
    }) { _ -> OHHTTPStubsResponse in
      let str = "test"
      let dic = ["a": str]
      let data = try? JSONSerialization.data(withJSONObject: dic, options: .init(rawValue: 0))
      return OHHTTPStubsResponse(data: data!, statusCode: 200, headers: nil)
    }
    
    // When
    var count = 3
    for _ in 0..<3 {
      _ = provider.requestNormal(target, callbackQueue: nil) { result in
        if let response = try? result.get(), let json = try? response.mapJSON() as? [String: String] {
          XCTAssert(json["a"] == "test", "json data failed")
        } else {
          XCTAssert((try? result.get()) != nil, "error should be nil")
        }
        count -= 1
        if count == 0 {
          exception.fulfill()
        }
      }
    }
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }
  
  func testStubRequest() {
    // Given
    let exception = expectation(description: "testStubRequest")
    let configuration = QuicksilverURLSessionConfiguration()
    let provider = QuicksilverProvider(configuration: configuration, plugins: [], callbackQueue: nil)
    let target = TestDataTargetType()

    // When
    provider.stubRequest(target, callbackQueue: nil, completion: { (result) in
      XCTAssert((try? result.get())?.statusCode == 200, "status code should be 200")
      XCTAssert((try? result.get())?.data.count == 0, "data response count is 0")
      exception.fulfill()
    }, stubBehavior: .immediate)
    
    // Then
    waitForExpectations(timeout: 3) { (error) in
      XCTAssert(error == nil, "timeout, internal error")
    }
  }
  
  func testGenerateRequest() {
    
    // Given
    struct ParamPlugin: PluginType {
      var extraParameters: [String: Any]? {
        return ["a": 1]
      }
      
      func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        return request
      }
      
      func willSend(_ request: URLRequest, target: TargetType) {
        
      }
      
      func didReceive(_ result: Result<Response, QuicksilverError>, target: TargetType) {
        
      }
      
      func process(_ result: Result<Response, QuicksilverError>, target: TargetType) -> Result<Response, QuicksilverError> {
        return result
      }
    }
    
    let configuration = QuicksilverURLSessionConfiguration(useHTTPDNS: false)
    let provider = QuicksilverProvider(configuration: configuration, plugins: [ParamPlugin()], callbackQueue: nil)
    
    let target = TestDataTargetType()
    
    // When
    let result = provider.getTargetRequest(target)
    
    // Then
    XCTAssert(result.0?.url?.absoluteString == "https://www.liulishuo.com/v1/test?a=1", "url should be equal")
  }
 
}
