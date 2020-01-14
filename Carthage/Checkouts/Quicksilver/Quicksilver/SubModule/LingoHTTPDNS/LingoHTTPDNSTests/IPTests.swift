//
//  IPTests.swift
//  LingoHTTPDNSTests
//
//  Created by Chun on 09/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoHTTPDNS

class IPTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testIsValidIPV4WithCorrectIPV4Address() {
    // Given
    let ipv4Address = "192.168.1.1"
    
    // When
    let result = ipv4Address.isValidIPV4()
    
    // Then
    XCTAssert(result)
  }
  
  func testIsValidIPV4WithWrongIPV4Address() {
    // Given
    let ipv4Address = "2001:4860:4860::8888"
    
    // When
    let result = ipv4Address.isValidIPV4()
    
    // Then
    XCTAssert(!result)
  }
  
  func testIsValidIPV6WithCorrectIPV6Address() {
    // Given
    let ipv6Address = "2001:4860:4860::8888"
    
    // When
    let result = ipv6Address.isValidIPV6()
    
    // Then
    XCTAssert(result)
  }
  
  func testIsValidIPV6WithWrongIPV6Address() {
    // Given
    let ipv6Address = "192.168.11"
    
    // When
    let result = ipv6Address.isValidIPV6()
    
    // Then
    XCTAssert(!result)
  }

}
