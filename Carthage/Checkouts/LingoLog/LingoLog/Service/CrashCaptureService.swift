//
//  CrashCaptureService.swift
//  LingoLog
//
//  Created by Chun on 2019/1/11.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

import Foundation
import LingoLogPrivate

// MARK: - CrashModel

struct CrashModel: CustomStringConvertible, CustomDebugStringConvertible {
  
  var description: String {
    return "\n[Crash Name]: \(name)\n[Crash Type]: \(type.rawValue)\n[Crash Reason]: \(reason)\n[App Info]: \n\(appInfo)\n[CallStack]: \(callStack)\n"
  }
  
  var debugDescription: String {
    return description
  }
  
  enum `Type`: String {
    case signal
    case exception
  }
  
  let type: Type
  let name: String
  let reason: String
  let appInfo: String
  let callStack: String
}

// MARK: CrashCaptureDelegate

protocol CrashCaptureDelegate: NSObjectProtocol {
  func crashCaptureDidCatchCrash(with model: CrashModel)
}

class WeakCrashCaptureDelegate {
  weak var delegate: CrashCaptureDelegate?
  
  init(delegate: CrashCaptureDelegate) {
    self.delegate = delegate
  }

}

// MARK: - CrashCaptureService

class CrashCaptureService: NSObject {
  
  static let shared = CrashCaptureService()

  private(set) var isOpen = false
  
  fileprivate var delegates = [WeakCrashCaptureDelegate]()
  
  private var signalActions: [Int32: sigaction] = [:]
  
  fileprivate var registeredActions: [Int32: sigaction] = [:]

  private var observer: NSObjectProtocol?
  
  func add(delegate: CrashCaptureDelegate) {
    delegates = delegates.filter {
      return $0.delegate != nil
    }
    
    let contains = delegates.contains {
      return $0.delegate?.hash == delegate.hash
    }
    
    if contains == false {
      let week = WeakCrashCaptureDelegate(delegate: delegate)
      delegates.append(week)
    }
    
    if delegates.count > 0 {
      open()
    }
    
  }
  
  func remove(delegate: CrashCaptureDelegate) {
    delegates = delegates.filter {
      return $0.delegate != nil
    }.filter {
      return $0.delegate?.hash != delegate.hash
    }
    
    if delegates.count == 0 {
      close()
    }
  }
  
  // MARK: - Private
  
  private func open() {
    guard isOpen == false else {
      return
    }
    LingoLogExceptionHandler.sharedInstance().delegate = self
    LingoLogExceptionHandler.sharedInstance().start()
    isOpen = true
  }
  
  private func close() {
    guard isOpen == true else {
      return
    }
    
    LingoLogExceptionHandler.sharedInstance().stop()
    
    isOpen = false
  }

}

extension CrashCaptureService: LingoLogExceptionHandlerDelegate {
  
  func handle(_ exception: NSException) {
    let callStack = exception.callStackSymbols.joined(separator: "\r")
    let reason = exception.reason ?? ""
    let name = exception.name
    
    let model = CrashModel(type: .exception,
                           name: name.rawValue,
                           reason: reason,
                           appInfo: appInfo(),
                           callStack: callStack)
    for delegate in delegates {
      delegate.delegate?.crashCaptureDidCatchCrash(with: model)
    }
  }
  
  func handleSignal(_ signal: Int32) {
    let callStack = Thread.callStackSymbols.joined(separator: "\r")
    let reason = "Signal \(name(of: signal))(\(signal)) was raised.\n"
    
    let model = CrashModel(type: .signal,
                           name: name(of: signal),
                           reason: reason,
                           appInfo: appInfo(),
                           callStack: callStack)
    
    for delegate in CrashCaptureService.shared.delegates {
      delegate.delegate?.crashCaptureDidCatchCrash(with: model)
    }
  }

}

func appInfo() -> String {
  let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? ""
  let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
  let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""
  #if os(macOS)
  return "App: \(displayName) \(shortVersion)(\(version))\n"
  #else
  let deviceModel = UIDevice.current.model
  let systemName = UIDevice.current.systemName
  let systemVersion = UIDevice.current.systemVersion
  return "App: \(displayName) \(shortVersion)(\(version))\n" +
    "Device:\(deviceModel)\n" + "OS Version:\(systemName) \(systemVersion)"
  #endif
}

func name(of signal: Int32) -> String {
  switch signal {
  case SIGABRT:
    return "SIGABRT"
  case SIGILL:
    return "SIGILL"
  case SIGSEGV:
    return "SIGSEGV"
  case SIGFPE:
    return "SIGFPE"
  case SIGBUS:
    return "SIGBUS"
  case SIGPIPE:
    return "SIGPIPE"
  case SIGSYS:
    return "SIGSYS"
  case SIGEMT:
    return "SIGEMT"
  case SIGTRAP:
    return "SIGTRAP"
  default:
    return "OTHER"
  }
}
