//
//  HTTPDNSServiceFactoryTests.swift
//  LingoHTTPDNSTests
//
//  Created by Chun on 09/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoHTTPDNS

class HTTPDNSServiceFactoryTests: XCTestCase {
  
  class HTTPDNSServiceSpy: HTTPDNSService {
    var responseIpAddress = "192.168.1.1"
    
    func query(_ domain: String, maxTTL: TTL, response: @escaping (DNSRecord?, Error?) -> Void) {
      let record = DNSRecord(ip: IP.ipv4(address: responseIpAddress), ttl: 300)
      response(record, nil)
    }
  }
  
  let service = HTTPDNSServiceFactory(service: HTTPDNSServiceSpy())
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testConfigDefaultService() {
    // Given
    let serviceSpy = HTTPDNSServiceSpy()
    serviceSpy.responseIpAddress = "8.8.8.9"
    
    let domain = "liulishuo.com"
    
    // When
    service.configDefaultService(serviceSpy)
    
    // Then
    let exception = expectation(description: "query")
    service.query(domain, maxTTL: 300) { (response, _) in
      XCTAssert(response?.ip.address == serviceSpy.responseIpAddress)
      exception.fulfill()
    }
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }
  
  func testQuery() {
    // Given
    let domain = "liulishuo.com"
    
    let serviceSpy = HTTPDNSServiceSpy()
    serviceSpy.responseIpAddress = "8.8.8.8"
    service.configDefaultService(serviceSpy)

    // When
    let exception = expectation(description: "query")
    service.query(domain, maxTTL: 300) { (record, _) in
      XCTAssert(record?.ip.address == "8.8.8.8")
      exception.fulfill()
    }
    
    // Then
    waitForExpectations(timeout: 3) { (_) in
        XCTAssert(true, "timeout")
    }
  }
  
}
