//
//  DataTracker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/12.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation
import ObjectiveC

// MARK: - DataTracker

public protocol DataTracker {
  func enterPage(pageName: String, pageCategory: String, properties: [String: Any]?)
  func action(actionName: String, properties: [String: Any]?)
  func action(actionName: String, pageCategory: String, pageName: String, properties: [String: Any]?)
}

extension DataTracker {
  func enter(page: String, properties: [String: Any]?) {
    enterPage(pageName: page, pageCategory: "russell_sdk", properties: properties)
  }
  
  func lazyAction(name: String, properties: [String: Any]?) -> () -> Void {
    return {
      self.action(actionName: name, properties: properties)
    }
  }
}

extension DataTracker {
  
  func child(extraParameters: [String: Any]) -> DataTracker {
    return _TrackerNode(parent: self, extraParameters: extraParameters)
  }
}

// MARK: - TrackerNode

final class _TrackerNode: DataTracker {
  
  private let parent: DataTracker
  private let extraParameters: [String: Any]
  init(parent: DataTracker, extraParameters: [String: Any]) {
    self.parent = parent
    self.extraParameters = extraParameters
  }
  
  func enterPage(pageName: String, pageCategory: String, properties: [String: Any]?) {
    // Child key/value pairs override parent extra parameters
    parent.enterPage(pageName: pageName, pageCategory: pageCategory, properties: extraParameters.merging(properties ?? [:], uniquingKeysWith: { $1 }))
  }
  
  func action(actionName: String, properties: [String: Any]?) {
    // Child key/value pairs override parent extra parameters
    parent.action(actionName: actionName, properties: extraParameters.merging(properties ?? [:], uniquingKeysWith: { $1 }))
  }
  
  func action(actionName: String, pageCategory: String, pageName: String, properties: [String: Any]?) {
    parent.action(actionName: actionName, pageCategory: pageCategory, pageName: pageName, properties: extraParameters.merging(properties ?? [:], uniquingKeysWith: { $1 }))
  }
  
}

// MARK: - Trackable

protocol _Trackable: class {
  var tracker: DataTracker? { get set }
}

private var _defaultTrackerKey = NSObject()
extension _Trackable where Self: NSObject {
  
  var tracker: DataTracker? {
    get {
      return objc_getAssociatedObject(self, &_defaultTrackerKey) as? DataTracker
    }
    set {
      objc_setAssociatedObject(self, &_defaultTrackerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}
