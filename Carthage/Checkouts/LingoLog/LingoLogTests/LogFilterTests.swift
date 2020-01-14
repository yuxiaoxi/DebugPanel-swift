//
//  LogFilterTests.swift
//  LingoLogTests
//
//  Created by Chun on 01/11/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoLog
@testable import LingoLogPrivate

class LogFilterTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testShouldBeLoggedWithMinLevelReach() {
    // Given
    let filter =  LogFilter(filterRule: LogFilterRule(minLevel: .debug, tagComparison: nil))
    
    // When
    let info = LogInfo(level: .debug, filename: "", funcname: "", line: 10, timeval: Darwin.timeval(), tid: 1, tag: "test", isCrashLog: false)
    let logged = filter.shouldBeLogged(logInfo: info)
    
    // Then
    XCTAssert(logged == true)
  }
  
  func testShouldBeLoggedWithMinLevelNotReach() {
    // Given
    let filter =  LogFilter(filterRule: LogFilterRule(minLevel: .error, tagComparison: nil))

    // When
    let info = LogInfo(level: .debug, filename: "", funcname: "", line: 10, timeval: Darwin.timeval(), tid: 1, tag: "test", isCrashLog: false)
    let logged = filter.shouldBeLogged(logInfo: info)
    
    // Then
    XCTAssert(logged == false)
  }
  
  func testShouldBeLoggedWithExcludes() {
    // Given
    let tagType = LogFilterRule.TagType(tag: "LingoLog", level: .debug)
    let filter = LogFilter(filterRule: LogFilterRule(minLevel: .debug, tagComparison: LogFilterRule.TagComparison.excludes(tagTypes: [tagType])))
    
    // When
    let info = LogInfo(level: .debug, filename: "", funcname: "", line: 10, timeval: Darwin.timeval(), tid: 1, tag: "LingoLog", isCrashLog: false)
    let logged = filter.shouldBeLogged(logInfo: info)
    
    // Then
    XCTAssert(logged == false)
  }
  
  func testShouldBeLoggedWithEquals() {
    // Given
    let tagType = LogFilterRule.TagType(tag: "LingoLog", level: .debug)
    let filter =  LogFilter(filterRule: LogFilterRule(minLevel: .debug, tagComparison: LogFilterRule.TagComparison.equals(tagTypes: [tagType], onlyEquals: true)))

    // When
    let info = LogInfo(level: .debug, filename: "", funcname: "", line: 10, timeval: Darwin.timeval(), tid: 1, tag: "LingoLog", isCrashLog: false)
    let logged = filter.shouldBeLogged(logInfo: info)
    
    // Then
    XCTAssert(logged == true)
  }
  
}
