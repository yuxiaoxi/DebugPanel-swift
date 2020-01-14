//
//  OneKeyReachabilityListener.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/9/30.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

protocol OnekeyReachabilityListener: class {
  func applicationActivityStatusChanged(_ isActive: Bool)
  func networkConnectionStatusChanged(_ isReachable: Bool)
}

final class OnekeyReachability {
  
  private let reachability = Reachability()
  private init() {}
  
  static let shared = OnekeyReachability()
  
  func startListening() {
    sendDummyNetworkRequest()
    startListeningReachability()
    registerNotifications()
  }
  
  // MARK: - listenning
  
  var isReachable: Bool {
    return reachability?.isReachable ?? false
  }
  
  private func startListeningReachability() {
    reachability?.listener = networkStatusChanged
    reachability?.startListening()
  }
  
  private func networkStatusChanged(_ status: Reachability.NetworkReachabilityStatus) {
    switch status {
    case .reachable:
      notifyStatusChange(true)
    default:
      notifyStatusChange(false)
    }
  }
  
  private func sendDummyNetworkRequest() {
    Russell.shared?.networkService.request(
      api: API(method: .get, path: "/", body: nil),
      extraErrorMapping: [],
      decoder: { $0 },
      completion: { (_: (Result<Data, Error>)) in }
    )
  }
  
  // MARK: - listeners
  
  private let lockQueue = DispatchQueue(label: "com.liulishuo.russell.network-listener", qos: .userInitiated)
  private var listeners: [OnekeyReachabilityListener] = []
  
  func registerListener(_ listener: OnekeyReachabilityListener) {
    lockQueue.async {
      guard !self.listeners.contains(where: { $0 === listener }) else { return }
      self.listeners.append(listener)
    }
  }
  
  func unregisterListener(_ listener: OnekeyReachabilityListener) {
    lockQueue.async {
      self.listeners.removeAll(where: { $0 === listener })
    }
  }
  
  private func notifyStatusChange(_ isReachable: Bool) {
    lockQueue.async {
      self.listeners.forEach { $0.networkConnectionStatusChanged(isReachable) }
    }
  }
  
  // MARK: - Application Status
  
  var isApplicationActive = true
  
  private func registerNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(_applicationDidActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(_applicationWillInactive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
  }
  
  @objc private func _applicationDidActive(_ notification: Notification) {
    Logger.info("OneKey _applicationDidActive at \(Date().timeIntervalSince1970)")
    isApplicationActive = true
    lockQueue.async {
      self.listeners.forEach { $0.applicationActivityStatusChanged(true) }
    }
  }
  
  @objc private func _applicationWillInactive(_ notification: Notification) {
    Logger.info("OneKey _applicationWillInactive at \(Date().timeIntervalSince1970)")
    isApplicationActive = false
    lockQueue.sync {
      listeners.forEach { $0.applicationActivityStatusChanged(false) }
    }
  }
}
