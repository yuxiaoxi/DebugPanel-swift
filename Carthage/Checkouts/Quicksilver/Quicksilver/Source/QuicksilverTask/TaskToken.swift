//
//  TaskToken.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/25.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

// MARK: - TaskToken

final class TaskToken: QuicksilverUploadTask, QuicksilverDownloadTask, QuicksilverDataTask {
  var taskIdentifier: Int
  
  let cancelAction: () -> Void
  let suspendAction: () -> Void
  let resumeAction: () -> Void
  
  private(set) var isCancelled = false
  private(set) var isRunning = false
  
  private var lock: DispatchSemaphore = DispatchSemaphore(value: 1)
  
  func finished() {
    _ = lock.wait(timeout: DispatchTime.distantFuture)
    defer { lock.signal() }
    guard isRunning else { return }
    isRunning = false
  }
  
  func cancel() {
    _ = lock.wait(timeout: DispatchTime.distantFuture)
    defer { lock.signal() }
    guard !isCancelled else { return }
    isCancelled = true
    cancelAction()
  }
  
  func resume() {
    _ = lock.wait(timeout: DispatchTime.distantFuture)
    defer { lock.signal() }
    guard !isCancelled else { return }
    guard !isRunning else { return }
    isRunning = true
    resumeAction()
  }
  
  func suspend() {
    _ = lock.wait(timeout: DispatchTime.distantFuture)
    defer { lock.signal() }
    guard !isCancelled else { return }
    guard isRunning else { return }
    isRunning = false
    suspendAction()
  }
  
  init(resumeAction: @escaping () -> Void, suspendAction: @escaping () -> Void, cancelAction: @escaping () -> Void, taskIdentifier: Int = UUID().uuidString.hashValue) {
    self.resumeAction = resumeAction
    self.suspendAction = suspendAction
    self.cancelAction = cancelAction
    self.taskIdentifier = taskIdentifier
  }
  
  convenience init(sessionTask: URLSessionTask) {
    self.init(resumeAction: {
      sessionTask.resume()
    }, suspendAction: {
      sessionTask.suspend()
    }, cancelAction: {
      sessionTask.cancel()
    }, taskIdentifier: sessionTask.taskIdentifier)
    
    if let sessionTask = sessionTask as? URLSessionDownloadTask {
      self.downloalCancelAction = { byProducingResumeData in
        sessionTask.cancel(byProducingResumeData: { (data) in
          byProducingResumeData(data)
        })
      }
    }
  }
  
  class func stubTask() -> TaskToken {
    let task = TaskToken(resumeAction: {
    }, suspendAction: {
    }, cancelAction: {
    })
    return task
  }
  
  class func simpleTask() -> TaskToken {
    let task = TaskToken(resumeAction: {
    }, suspendAction: {
    }, cancelAction: {
    })
    return task
  }
  
  // MARK: - Download
  
  var downloalCancelAction: ((@escaping (Data?) -> Void) -> Void)?
  
  func cancel(byProducingResumeData completionHandler: @escaping (Data?) -> Void) {
    _ = lock.wait(timeout: DispatchTime.distantFuture)
    defer { lock.signal() }
    guard !isCancelled else { return }
    isCancelled = true
    downloalCancelAction?(completionHandler)
  }
  
}
