//
//  ViewController.swift
//  LingoLogDemo
//
//  Created by Chun on 02/04/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import UIKit
import LingoLog

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    LoggerTool.logPlugins = [LingoLogDemoCustomPlugin()]
    LoggerTool.configCrashCapture(open: true)
    LoggerTool.appendIDEOutput(filterRule: nil, asynchronously: false)
    LoggerTool.appendLiveLogOutput(filterRule: nil)
    LoggerTool.appendFileOutput(filename: "test")
    
    Logger.debug(NSTemporaryDirectory())
    Logger.error("aaa", "bbb")

    for index in 0..<10 {
      Logger.debug("test == \(index)")
      Logger.debug("test2 == \(index)", "a")
    }
    
    DispatchQueue.global().async {
      for index in 0..<10 {
        Logger.debug("async test == \(index)")
        Logger.debug("async test2 == \(index)", "a")
      }
    }
    
  }
  
  @IBAction func handleLogButtonTapped() {
    Logger.debug("log button tapped")
    let panel = LoggerTool.getLogPanel()
    navigationController?.pushViewController(panel, animated: true)
  }

}

class LingoLogDemoCustomPlugin: LingoLogPlugin {
    
  func handleLingoLogError(_ errorCode: Int, message: String?) {
    print(errorCode)
  }

  func handleLog(level: LogLevel, message: Any, tag: String?, file: String, function: String, line: Int) {
    
  }
}
