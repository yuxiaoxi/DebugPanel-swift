//
//  HTTPDNSTests.swift
//  LingoHTTPDNSTests
//
//  Created by Chun on 09/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoHTTPDNS

class HTTPDNSTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testConstructHTTPDNSResult() {
    // Given
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 50)
    let fromCached = true
    
    // When
    let result = HTTPDNS().constructHTTPDNSResult(record: record, fromCached: fromCached)
    
    // Then
    XCTAssert(result.fromCached)
    XCTAssert(result.timeout < Date().timeIntervalSince1970 + record.ttl)
  }
  
  func testCacheDNSResult() {
    // Given
    let httpDNS = HTTPDNS()
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 50)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"
    
    // When
    let exception = expectation(description: "cache")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      let result = httpDNS.getDNSResultFromCache(domain: domain)
      XCTAssert(result != nil)
      XCTAssert(result!.ipAddress == "8.8.8.8")
      exception.fulfill()
    }
    
    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }

  func testCacheDNSResultWithSomeValues() {
    // Given
    let httpDNS = HTTPDNS()

    let record1 = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 50)
    let result1 = httpDNS.constructHTTPDNSResult(record: record1)
    let domain1 = "liulishuo.com"

    let record2 = DNSRecord(ip: IP.ipv4(address: "8.8.8.9"), ttl: 50)
    let result2 = httpDNS.constructHTTPDNSResult(record: record2)
    let domain2 = "liulishuo2.com"

    // When

    let exception1 = expectation(description: "cache1")
    httpDNS.cacheDNSResult(result: result1, with: domain1) {
      let result = httpDNS.getDNSResultFromCache(domain: domain1)
      XCTAssert(result != nil)
      XCTAssert(result!.ipAddress == "8.8.8.8")
      exception1.fulfill()
    }

    let exception2 = expectation(description: "cache2")
    httpDNS.cacheDNSResult(result: result2, with: domain2) {
      let result = httpDNS.getDNSResultFromCache(domain: domain2)
      XCTAssert(result != nil)
      XCTAssert(result!.ipAddress == "8.8.8.9")
      exception2.fulfill()
    }

    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }

  }

  func testGetDNSFromCacheWithValidCache() {
    // Given
    let httpDNS = HTTPDNS()
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 50)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"

    // When
    let exception = expectation(description: "get")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      if let dnsResult = httpDNS.getDNSResultFromCache(domain: domain) {
        XCTAssert(dnsResult.ipAddress == "8.8.8.8")
      } else {
        XCTFail("get dns from cache failed")
      }
      exception.fulfill()
    }

    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }

  func testGetDNSFromCacheWithInvalidCache() {
    // Given
    let httpDNS = HTTPDNS()
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 0)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"

    // When
    let exception = expectation(description: "get")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      XCTAssert(httpDNS.getDNSResultFromCache(domain: domain) == nil)
      exception.fulfill()
    }

    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }

  func testInvalidAllDNSCache() {
    // Given
    let httpDNS = HTTPDNS()
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 0)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"

    // When
    let exception = expectation(description: "invalid")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      httpDNS.invalidAllDNSCache {
        XCTAssert(httpDNS.getDNSResultFromCache(domain: domain) == nil)
        exception.fulfill()
      }
    }
    
    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }
  
  func testSetDomainCacheFailed() {
    // Given
    let httpDNS = HTTPDNS()
    let record = DNSRecord(ip: IP.ipv4(address: "8.8.8.8"), ttl: 0)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"
    
    // When
    let exception = expectation(description: "SetDomainCacheFailed")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      httpDNS.setDomainCacheFailed(domain, complete: {
        XCTAssert(httpDNS.getDNSResultFromCache(domain: domain) == nil)
        exception.fulfill()
      })
    }
    
    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }
  
  func testGetOriginDomain() {
    // Given
    let httpDNS = HTTPDNS()
    let ip = IP.ipv4(address: "8.8.8.8")
    let record = DNSRecord(ip: ip, ttl: 0)
    let result = httpDNS.constructHTTPDNSResult(record: record, fromCached: false)
    let domain = "liulishuo.com"
    
    // When
    let exception = expectation(description: "GetOriginDomain")
    httpDNS.cacheDNSResult(result: result, with: domain) {
      XCTAssert(httpDNS.getOriginDomain(ipAddress: "8.8.8.8") == domain)
      exception.fulfill()
    }
    
    // Then
    waitForExpectations(timeout: 3) { (_) in
      XCTAssert(true, "timeout")
    }
  }
  
}
