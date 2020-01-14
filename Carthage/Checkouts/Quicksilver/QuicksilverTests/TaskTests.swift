//
//  CancellableTests.swift
//  QuicksilverTests
//
//  Created by Chun on 26/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
@testable import Quicksilver

class TaskTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testTaskTokenCancel() {
    // Given
    let taskToken = TaskToken.stubTask()
    
    // When
    taskToken.cancel()
    
    // Then
    XCTAssert(taskToken.isCancelled, "cancelToken should be cancelled")
  }

  func testTaskTokenResume() {
    // Given
    let taskToken = TaskToken.stubTask()
    
    // When
    taskToken.resume()
    
    // Then
    XCTAssert(taskToken.isRunning, "cancelToken should be running")
  }
  
  func testTaskTokenSuspend() {
    // Given
    let taskToken = TaskToken.stubTask()
    
    // When
    taskToken.suspend()
    
    // Then
    XCTAssert(!taskToken.isRunning, "cancelToken should not be running")
  }
  
  func testTaskTokenCancelByProducingResumeData() {
    // Given
    let taskToken = TaskToken.simpleTask()
    taskToken.downloalCancelAction = { dataCallback in
      dataCallback(nil)
    }
    
    var result: Data? = Data()
    
    // When
    taskToken.cancel { (data) in
      result = data
    }
    
    // Then
    XCTAssert(result == nil)
  }
  
}
