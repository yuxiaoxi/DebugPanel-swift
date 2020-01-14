//
//  TargetTypeTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import AFNetworkingPrivate
@testable import Quicksilver

class TargetTypeTests: XCTestCase {
  
  class TestDataTargetType: DataTargetType {
    
    var baseURL: URL {
      return URL(string: "https://www.apple.com/v1")!
    }
    
    var path: String {
      return "test"
    }
    
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

  func testDataTargetTypeFullRequestURL() {
    // Given
    let target = TestDataTargetType()
    
    // When
    let url = target.fullRequestURL
    print(url.absoluteString)
    // Then
    XCTAssert(url.absoluteString == "https://www.apple.com/v1/test", "url should be equal")
  }
  
}
