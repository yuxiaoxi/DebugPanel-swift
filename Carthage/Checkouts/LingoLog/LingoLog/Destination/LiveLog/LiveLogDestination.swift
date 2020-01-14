//
//  LiveLogDestination.swift
//  LingoLog
//
//  Created by Roc Zhang on 2018/7/12.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

class LiveLogDestination: LoggerDestination {

  private let mcManager = MultipeerConnectivityConnectionManager()
  
  override var defaultHashValue: Int {
    return 4
  }
  
  override init() {
    super.init()
    
    mcManager.setReadyForConnect()
  }
  
  deinit {
    mcManager.disconnectAllConnection()
  }
  
  @discardableResult override func send(logInfo: LogInfo, message: String) -> String {
    let message = super.send(logInfo: logInfo, message: message)
    sendLog(message)
    return message
  }
  
  private func sendLog(_ text: String) {
    mcManager.send(content: text, eventType: .log)
  }
  
}
