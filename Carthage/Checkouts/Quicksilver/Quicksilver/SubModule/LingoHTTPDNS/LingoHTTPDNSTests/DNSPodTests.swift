//
//  DNSPodTests.swift
//  LingoHTTPDNSTests
//
//  Created by Chun Ye on 2018/4/16.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoHTTPDNS

class DNSPodTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testDNSPodParse1() {
    // Given
    let raw = "220.181.57.216;111.13.101.208,146"
    let ttl: TTL = 100
    
    // When
    let result = dnsPodParse(raw, ttl: ttl)
    
    // Then
    XCTAssert(result != nil)
    XCTAssert(result!.ip.address == "220.181.57.216")
    XCTAssert(result!.ttl == 100)
  }
  
  func testDNSPodParse2() {
    // Given
    let raw = "220.181.57.216;111.13.101.208,146"
    let ttl: TTL = 152
    
    // When
    let result = dnsPodParse(raw, ttl: ttl)
    
    // Then
    XCTAssert(result != nil)
    XCTAssert(result!.ip.address == "220.181.57.216")
    XCTAssert(result!.ttl == 146)
  }
  
  func testDNSPodParse3() {
    // Given
    let raw = "111.13.101.208,146"
    let ttl: TTL = 152
    
    // When
    let result = dnsPodParse(raw, ttl: ttl)
    
    // Then
    XCTAssert(result != nil)
    XCTAssert(result!.ip.address == "111.13.101.208")
    XCTAssert(result!.ttl == 146)
  }
  
  func testDNSPodParse4() {
    // Given
    let raw = ";,146"
    let ttl: TTL = 152
    
    // When
    let result = dnsPodParse(raw, ttl: ttl)
    
    // Then
    XCTAssert(result == nil)
  }
  
  func testDNSPodParse5() {
    // Given
    let raw = "aaaa;bbb,146"
    let ttl: TTL = 152
    
    // When
    let result = dnsPodParse(raw, ttl: ttl)
    
    // Then
    XCTAssert(result == nil)
  }
  
}
