//
//  ResponseTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import Quicksilver

class ResponseTests: XCTestCase {
  
  struct Test: Decodable {
    let a: Int
  }
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testFilterStatusCodes() {
    // Given
    let response = Response(statusCode: 200, data: Data())
    
    // When
    let chainResponse1 = try? response.filter(statusCodes: 0...20)
    let chainResponse2 = try? response.filter(statusCodes: 200...201)

    // Then
    XCTAssert(chainResponse1 == nil, "chainResponse1 should be nil")
    XCTAssert(chainResponse2 != nil, "chainResponse2 should not be nil")
  }
  
  func testFilterStatusCode() {
    // Given
    let response = Response(statusCode: 200, data: Data())
    
    // When
    let chainResponse1 = try? response.filter(statusCode: 100)
    let chainResponse2 = try? response.filter(statusCode: 200)
    
    // Then
    XCTAssert(chainResponse1 == nil, "chainResponse1 should be nil")
    XCTAssert(chainResponse2 != nil, "chainResponse2 should not be nil")
  }
  
  func testFilterSuccessfulStatusCodes() {
    // Given
    let response1 = Response(statusCode: 300, data: Data())
    let response2 = Response(statusCode: 200, data: Data())

    // When
    let chainResponse1 = try? response1.filterSuccessfulStatusCodes()
    let chainResponse2 = try? response2.filterSuccessfulStatusCodes()
    
    // Then
    XCTAssert(chainResponse1 == nil, "chainResponse1 should be nil")
    XCTAssert(chainResponse2 != nil, "chainResponse2 should not be nil")
  }

  func testFilterSuccessfulStatusAndRedirectCodes() {
    // Given
    let response1 = Response(statusCode: 400, data: Data())
    let response2 = Response(statusCode: 300, data: Data())
    
    // When
    let chainResponse1 = try? response1.filterSuccessfulStatusAndRedirectCodes()
    let chainResponse2 = try? response2.filterSuccessfulStatusAndRedirectCodes()
    
    // Then
    XCTAssert(chainResponse1 == nil, "chainResponse1 should be nil")
    XCTAssert(chainResponse2 != nil, "chainResponse2 should not be nil")
  }

  func testMapStringWithoutKeyPath() {
    // Given
    let str = "test"
    let response = Response(statusCode: 200, data: str.data(using: .utf8)!)
    
    // When
    let mapString = try? response.mapString()
    
    // Then
    XCTAssert(mapString == str, "mapString should be equal str")
  }
  
  func testMapStringWithKeyPath() {
    // Given
    let str = "test"
    let dic = ["a": str]
    let data = try? JSONSerialization.data(withJSONObject: dic, options: .init(rawValue: 0))
    let response = Response(statusCode: 200, data: data!)
    
    // When
    let mapString = try? response.mapString(atKeyPath: "a")
    
    // Then
    XCTAssert(mapString == str, "mapString should be equal str")
  }
  
  func testMapJSONWithFailsOnEmptyData() {
    // Given
    let response = Response(statusCode: 200, data: Data())

    // When
    var containError = false
    do {
      _ = try response.mapJSON(failsOnEmptyData: true)
    } catch {
      containError = true
    }
    XCTAssert(containError, "should be error")
  }
  
  func testMapJSONWithoutFailsOnEmptyData() {
    // Given
    let dic = [String: String]()
    let data = try? JSONSerialization.data(withJSONObject: dic, options: .init(rawValue: 0))
    let response = Response(statusCode: 200, data: data!)
    
    // When
    let json = try? response.mapJSON(failsOnEmptyData: false)
    
    // Then
    XCTAssert(json != nil, "json data should be nil")
  }

  func testMap() {
    // Given
    let value = 1
    let dic = ["a": value]
    let data = try? JSONSerialization.data(withJSONObject: dic, options: .init(rawValue: 0))
    let response = Response(statusCode: 200, data: data!)
    
    // When
    let testModel = try? response.map(Test.self)
    
    // Then
    XCTAssert(testModel?.a == 1, "a should be 1")
  }

}
