//
//  QuicksilverHTTPResponseSerializationTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import Quicksilver

class QuicksilverHTTPResponseSerializationTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testResponseObject() {
    // Given
    let url = URL(string: "https://www.apple.com/v1/")!
    let response = HTTPURLResponse(url: url, statusCode: 300, httpVersion: nil, headerFields: nil)
    let serialization = QuicksilverHTTPResponseSerialization()
    
    // When
    var error: NSError?
    let data = serialization.responseObject(for: response, data: Data(), error: &error)
    
    // Then
    XCTAssert(data != nil, "data should not be nil")
  }

}
