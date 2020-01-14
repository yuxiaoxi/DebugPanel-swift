//
//  QuicksilverResponseSerialization.swift
//  Quicksilver
//
//  Created by Chun on 20/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

class QuicksilverHTTPResponseSerialization: NSObject, AFURLResponseSerialization {
  
  override init() {
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("QuicksilverHTTPResponseSerialization not support NSSecureCoding")
  }
  
  func encode(with aCoder: NSCoder) {
    fatalError("QuicksilverHTTPResponseSerialization not support NSSecureCoding")
  }
  
  static var supportsSecureCoding: Bool {
    fatalError("QuicksilverHTTPResponseSerialization not support NSSecureCoding")
  }
  
  func copy(with zone: NSZone? = nil) -> Any {
    fatalError("QuicksilverHTTPResponseSerialization not support NSCopying")
  }
  
  func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
    return data
  }

}
