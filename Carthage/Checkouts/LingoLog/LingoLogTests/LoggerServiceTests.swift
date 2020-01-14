//
//  LoggerService.swift
//  LingoLogTests
//
//  Created by Chun on 01/11/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import LingoLog
@testable import LingoLogPrivate

class LoggerServiceTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }

  func testDispatchSendNotCalled() {
    // Given
    let logLevel = LogLevel.debug
    let message = "testDispatchSendGenerageLogMessage"
    let file = "LoggerServiceTests.swift"
    let function = "dispatchSend"
    let line = 19
    let destinationSpy = LoggerDestinationSpy()
    destinationSpy.asynchronously = false
    let tagType = LogFilterRule.TagType(tag: "Unit Test", level: .debug)
    destinationSpy.logFilter = LogFilter(filterRule: LogFilterRule(minLevel: .warning, tagComparison: .equals(tagTypes: [tagType], onlyEquals: false)))
    LoggerService.shared.destinations.insert(destinationSpy)
    
    // When
    LoggerService.shared.dispatchSend(level: logLevel, message: message, tag: "Unit2 Test", file: file, function: function, line: line)
    
    // Then
    XCTAssert(!destinationSpy.sendCalled)
  }
  
  func testDispatchSendCalled() {
    // Given
    let level = LogLevel.debug
    let message = "testDispatchSendGenerageLogMessage"
    let file = "LoggerServiceTests.swift"
    let function = "dispatchSend"
    let line = 19
    let destinationSpy = LoggerDestinationSpy()
    destinationSpy.asynchronously = false
    let tagType = LogFilterRule.TagType(tag: "Unit Test", level: .debug)
    destinationSpy.logFilter = LogFilter(filterRule: LogFilterRule(minLevel: .debug, tagComparison: .equals(tagTypes: [tagType], onlyEquals: false)))
    LoggerService.shared.destinations.insert(destinationSpy)
    
    // When
    LoggerService.shared.dispatchSend(level: level, message: message, tag: "Unit Test", file: file, function: function, line: line)

    // Then
    XCTAssert(destinationSpy.sendCalled)
  }
  
  func testFileNameOfFile() {
    // Given
    let filePath = "/var/folders/tq/bv9f4lw10txbd196lvhlf3100000gn/T/com.apple.dt.XCTest/IDETestRunSession-51763AC0-0ED2-45FB-93BD-B7BA072B092F/LingoLogTests-4B58F21E-3323-41B2-A2DB-C57C6BFC7AFB/Session-LingoLogTests-2017-11-01_192646-aJ4oh7.log"
    
    // When
    let fileName = LoggerService.fileNameOfFile(filePath)
    
    // Then
    XCTAssert(fileName == "Session-LingoLogTests-2017-11-01_192646-aJ4oh7.log")
  }
  
  func testFileNameWithoutSuffix() {
    // Given
    let filePath = "/var/folders/tq/bv9f4lw10txbd196lvhlf3100000gn/T/com.apple.dt.XCTest/IDETestRunSession-51763AC0-0ED2-45FB-93BD-B7BA072B092F/LingoLogTests-4B58F21E-3323-41B2-A2DB-C57C6BFC7AFB/Session-LingoLogTests-2017-11-01_192646-aJ4oh7.log"
    
    // When
    let fileName = LoggerService.fileNameWithoutSuffix(filePath)
    
    // Then
    XCTAssert(fileName == "Session-LingoLogTests-2017-11-01_192646-aJ4oh7")
  }
  
  // MARK: - SPY
  
  class LoggerDestinationSpy: LoggerDestination {
    var sendCalled = false
    override func send(logInfo: LogInfo, message: String) -> String {
      sendCalled = true
      return message
    }
  }
  
}
