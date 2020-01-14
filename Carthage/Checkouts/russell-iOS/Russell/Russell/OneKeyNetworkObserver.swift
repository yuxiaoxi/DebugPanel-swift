//
//  OneKeyNetworkObserver.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/9/30.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

private final class TimerWrapper {
  
  private let timeout: TimeInterval
  private var action: (() -> Void)?
  init(timeout: TimeInterval, action: @escaping () -> Void) {
    self.timeout = timeout
    self.action = action
    setup()
  }
  
  private var timer: Timer?
  
  private func setup() {
    timer = Timer(timeInterval: timeout, repeats: false) { [weak self] _ in
      guard let self = self else { return }
      
      self.action?()
      self.action = nil
    }
  }
  
  func pause() {
    Logger.info("Pause network timer at \(Date().timeIntervalSince1970)")
    timer?.invalidate()
    setup()
  }
  
  func resume() {
    Logger.info("Resume network timer at \(Date().timeIntervalSince1970)")
    timer.map { RunLoop.main.add($0, forMode: .common) }
  }
  
  func invalidate() {
    Logger.info("invalidate network timer at \(Date().timeIntervalSince1970)")
    timer?.invalidate()
    timer = nil
  }
}

final class OneKeyNetworkObserver {
  
  private let timeout: TimeInterval
  private var task: (() -> Bool)?
  private var completion: ((Bool) -> Void)?
  init(timeout: TimeInterval, task: @escaping () -> Bool, completion: @escaping (Bool) -> Void) {
    self.timeout = timeout
    self.task = task
    self.completion = completion
  }
  
  private var timer: TimerWrapper?
  private let completionLockQueue = DispatchQueue(label: "com.liulishuo.russell.network-observer.sub", qos: .userInitiated)
  
  func tryTask(retriesIfConnected: Bool) {
    guard let task = task else { return }
    DispatchQueue.global(qos: .userInitiated).async {
      let result = task()
      self.completeOnce(result)
    }
  }
}

extension OneKeyNetworkObserver: OnekeyReachabilityListener {
  
  func applicationActivityStatusChanged(_ isActive: Bool) {
    if isActive {
      Logger.info("Application activated at \(Date().timeIntervalSince1970)")
      self._stopNetworkListenning()
      self.completeOnce(true)
    } else {
      guard !OnekeyReachability.shared.isApplicationActive else {
        return _stopNetworkListenning()
      }
    }
  }
  
  func networkConnectionStatusChanged(_ isReachable: Bool) {
    guard isReachable else { return }
    Logger.info("Network connected at \(Date().timeIntervalSince1970)")
  }
}

extension OneKeyNetworkObserver {
  
  private func completeOnce(_ result: Bool) {
    completionLockQueue.async {
      Logger.info("One key completeOnce \(Date().timeIntervalSince1970)")
      guard let completion = self.completion else { return }
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
  
  func startNetworkListenning() {
    OnekeyReachability.shared.registerListener(self)
    // setup timeout
    // designed retain cycle
    timer = TimerWrapper(timeout: self.timeout, action: { [weak self] in
      Logger.info("Action network timer at \(Date().timeIntervalSince1970)")
      guard let self = self else { return }
      
      self._stopNetworkListenning()
      self.completeOnce(true)
    })
    
    if OnekeyReachability.shared.isApplicationActive {
      timer?.resume()
    }
  }
  
  private func _stopNetworkListenning() {
    timer?.invalidate()
    timer = nil
    
    OnekeyReachability.shared.unregisterListener(self)
  }
}
