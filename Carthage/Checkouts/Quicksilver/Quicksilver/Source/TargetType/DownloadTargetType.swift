//
//  DownloadTargetType.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/21.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

// MARK: - Downloadable

public protocol Downloadable {
  var url: URL { get }
  var resumeData: Data? { get }
}

extension URL: Downloadable {
  public var url: URL {
    return self
  }
  
  public var resumeData: Data? {
    return nil
  }
}

// MARK: - DownloadTargetType

public protocol DownloadTargetType: TargetType {
  /// download resource for downloading
  var resource: Downloadable { get }
  
  /// A file download task to a destination. Default value is `suggestedDownloadDestination` default config.
  var downloadDestination: DownloadFileDestination { get }
}

public extension DownloadTargetType {
  
  /// Default value is `.successCodes`.
  var validation: ValidationType {
    return .successCodes
  }
  
  /// Default value is `suggestedDownloadDestination` default value.
  var downloadDestination: DownloadFileDestination {
    return suggestedDownloadDestination()
  }
  
  /// Default value is `GET` on DownloadTargetType
  var method: HTTPMethod {
    return .get
  }
  
  /// Default value is nil.
  var parameters: [String: Any]? {
    return nil
  }
  
  var headers: [String: String]? {
    return nil
  }
  
  var fullRequestURL: URL {
    return resource.url
  }
  
  var priority: Float {
    return 0.5
  }
 
  var timeoutInterval: TimeInterval? {
    return nil
  }
}

// MARK: - Download Helper Types

/// A closure executed once a download request has successfully completed in order to determine where to move the
/// temporary file written to during the download process. The closure takes two arguments: the temporary file URL
/// and the URL response, and returns a two arguments: the file URL where the temporary file should be moved and
/// the options defining how the file should be moved.
public typealias DownloadFileDestination = (
  _ temporaryURL: URL,
  _ response: URLResponse)
  -> URL

/// Creates a download file destination closure which uses the default file manager to move the temporary file to a
/// file URL in the first available directory with the specified search path directory and search path domain mask.
///
/// - parameter directory: The search path directory. `.DocumentDirectory` by default.
/// - parameter domain:    The search path domain mask. `.UserDomainMask` by default.
///
/// - returns: A download file destination closure.
public func suggestedDownloadDestination(
  for directory: FileManager.SearchPathDirectory = .documentDirectory,
  in domain: FileManager.SearchPathDomainMask = .userDomainMask)
  -> DownloadFileDestination {
  return { temporaryURL, response in
    let directoryURLs = FileManager.default.urls(for: directory, in: domain)
    
    if let suggestedFilename = response.suggestedFilename, !directoryURLs.isEmpty {
      return directoryURLs[0].appendingPathComponent(suggestedFilename)
    }
    
    return temporaryURL
  }
}
