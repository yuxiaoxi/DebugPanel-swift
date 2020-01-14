//
//  Stub.swift
//  Quicksilver
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// Mark: Stubbing

/// Controls how stub responses are returned.
public enum StubBehavior {
  
  /// Do not stub.
  case never
  
  /// Return a response immediately.
  case immediate
  
  /// Return a response after a delay.
  case delayed(seconds: TimeInterval)
}
