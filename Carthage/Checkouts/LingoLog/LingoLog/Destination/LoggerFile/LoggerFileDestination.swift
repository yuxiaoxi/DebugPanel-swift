//
//  LoggerFileDestination.swift
//  LingoLog
//
//  Created by Chun on 16/10/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import Foundation

class LoggerFileDestination: LoggerDestination {
  
  override var defaultHashValue: Int {
    return 2
  }
  
  let fileManager = FileManager()
  var fileHandle: FileHandle?

  private var logFileURL: URL?

  init(filename: String) {
    super.init()
    logFileURL = registerNewLogFile(with: filename)
  }
  
  deinit {
    fileHandle?.closeFile()
  }
  
  @discardableResult override func send(logInfo: LogInfo, message: String) -> String {
    let message = super.send(logInfo: logInfo, message: message)
    save(toFile: "\(message)\n")
    return message
  }
    
  @discardableResult func save(toFile str: String) -> Bool {
    guard let url = logFileURL else { return false }
    
    do {
      if !fileManager.fileExists(atPath: url.path) {
        try str.write(to: url, atomically: true, encoding: .utf8)
      } else {
        if fileHandle == nil {
          fileHandle = try FileHandle(forWritingTo: url)
        }
        
        if let fileHandle = fileHandle {
          _ = fileHandle.seekToEndOfFile()
          if let data = str.data(using: .utf8) {
            fileHandle.write(data)
          }
        }
      }
      return true
    } catch {
      return false
    }
  }
  
  func clearFileHandle() {
    if asynchronously {
      queue.async {
        self.fileHandle?.closeFile()
        self.fileHandle = nil
      }
    } else {
      queue.sync {
        self.fileHandle?.closeFile()
        self.fileHandle = nil
      }
    }
  }

}

extension LoggerFileDestination {
  
  private func getFileSize(filepath: String) -> UInt64? {
    if let attr = try? fileManager.attributesOfItem(atPath: filepath), let size = attr[FileAttributeKey.size] as? UInt64 {
      return size
    } else {
      return nil
    }
  }
  
  private func registerNewLogFile(with fileName: String) -> URL? {
    if let baseLogDirectory = LoggerFileDestination.baseLogDirectory {
      if !fileManager.fileExists(atPath: baseLogDirectory.path) {
        try? fileManager.createDirectory(at: baseLogDirectory, withIntermediateDirectories: false, attributes: nil)
      }
      let logFileSuffix = "_\(fileName).log"
      var fileIndex = 1
      if let logFiles = try? fileManager.contentsOfDirectory(atPath: baseLogDirectory.path), logFiles.count > 0 {
        for file in logFiles where file.hasSuffix(logFileSuffix) {
          let fullFilepath = baseLogDirectory.appendingPathComponent(file)
          if let size = getFileSize(filepath: fullFilepath.path), size > 1024 * 1024 * 5 {
            let indexString = file.replacingOccurrences(of: logFileSuffix, with: "")
            if let index = Int(indexString), fileIndex <= index {
              fileIndex += 1
            }
          }
        }
      }
      return baseLogDirectory.appendingPathComponent("\(fileIndex)\(logFileSuffix)")
    } else {
      return nil
    }
  }

}

extension LoggerFileDestination {
  
  static var baseLogDirectory: URL? {
    if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
      return url.appendingPathComponent("LingoLog", isDirectory: true)
    } else {
      return nil
    }
  }
  
  static func getAllAvailableLogFilePaths() -> [String] {
    var availableLogFilePaths = [String]()
    if let baseLogDirectory = baseLogDirectory, let paths = FileManager.default.subpaths(atPath: baseLogDirectory.path), paths.count > 0 {
      for path in paths {
        let logURL = baseLogDirectory.appendingPathComponent(path)
        if logURL.pathExtension == "log" {
          availableLogFilePaths.append(logURL.path)
        }
      }
    }
    return availableLogFilePaths
  }

}
