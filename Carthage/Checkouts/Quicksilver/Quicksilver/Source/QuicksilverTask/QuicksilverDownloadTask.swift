//
//  QuicksilverDownloadTask.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/25.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

// MARK: - QuicksilverDownloadTask

public protocol QuicksilverDownloadTask: QuicksilverTask {
  func cancel(byProducingResumeData completionHandler: @escaping (Data?) -> Void)
}
