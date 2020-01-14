//
//  DummyDataTracker.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2019/8/16.
//  Copyright © 2019 LLS. All rights reserved.
//

@testable import Russell

final class DummyDataTracer: DataTracker {
  func action(actionName: String, pageCategory: String, pageName: String, properties: [String : Any]?) {
    
  }
  
  
  func enterPage(pageName: String, pageCategory: String, properties: [String: Any]?) {
    
  }
  
  func action(actionName: String, properties: [String: Any]?) {
    
  }
  
  func action(actionName: String, pageCategory: String, pageName: String, properties: [String: Any]?) {
    
  }
}
