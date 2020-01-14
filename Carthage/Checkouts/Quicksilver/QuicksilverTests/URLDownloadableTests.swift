//
//  URLDownloadableTests.swift
//  QuicksilverTests
//
//  Created by Chun Ye on 2018/9/26.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import XCTest
import Quicksilver

class URLDownloadableTests: XCTestCase {
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testURLDownloadable() {
    // Given
    let urlString = "https://www.liulishuo.com"
    let downloadable: Downloadable = URL(string: urlString)!
    
    // When
    let downloadURL = downloadable.url
    let resumedData = downloadable.resumeData
    
    // Then
    XCTAssert(downloadURL.absoluteString == urlString)
    XCTAssert(resumedData == nil)
  }
  
}
