//
//  LoggerIDEDestination.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

class LoggerXcodeDestination: LoggerDestination {
  
  override var defaultHashValue: Int {
    return 1
  }
  
  override init() {
    super.init()
  }
  
  @discardableResult override func send(logInfo: LogInfo, message: String) -> String {
    let sendMessage = super.send(logInfo: logInfo, message: message)
    print(sendMessage, separator: "\n", terminator: "\n")
    return sendMessage
  }

}
