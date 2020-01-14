//
//  QuicksilverTask.swift
//  Quicksilver
//
//  Created by Chun on 2018/5/23.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

// MARK: - QuicksilverTask

public protocol QuicksilverTask {
  var isCancelled: Bool { get }
  var isRunning: Bool { get }
  var taskIdentifier: Int { get }

  func resume()
  func suspend()
  func cancel()
}

public protocol QuicksilverDataTask: QuicksilverTask {}

public protocol QuicksilverUploadTask: QuicksilverTask {}
