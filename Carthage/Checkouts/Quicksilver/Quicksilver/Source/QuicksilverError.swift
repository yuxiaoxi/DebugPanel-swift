//
//  QuicksilverError.swift
//  Quicksilver
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// A type representing possible errors Quicksilver can throw.
public enum QuicksilverError: Error {  
  /// Indicates a response failed due to an underlying `Error`.
  case underlying(Error, Response?)
  
  /// Indicates that an `TargetType` failed to map to a `URLRequest`.
  case requestMapping(TargetType)
  
  /// Indicates a response failed with an invalid HTTP status code.
  case statusCode(Response)
  
  /// Indicates a response failed to map to a JSON structure.
  case jsonMapping(Response)
  
  /// Indicates a response failed to map to a String.
  case stringMapping(Response)
  
  /// Indicates a response failed to map to a Decodable object.
  case objectMapping(Error, Response)

}

public extension QuicksilverError {
  /// Depending on error type, returns a `Response` object.
  var response: Response? {
    switch self {
    case .jsonMapping(let response): return response
    case .stringMapping(let response): return response
    case .objectMapping(_, let response): return response
    case .statusCode(let response): return response
    case .underlying(_, let response): return response
    case .requestMapping: return nil
    }
  }

}

// MARK: - Error Descriptions

extension QuicksilverError: CustomStringConvertible, CustomDebugStringConvertible {

  public var debugDescription: String {
    return description
  }

  public var description: String {
    switch self {
    case .jsonMapping(let response):
      return "Failed to map data to JSON. \nAnd with response \(response)"
    case .stringMapping(let response):
      return "Failed to map data to a String. \nAnd with response \(response)"
    case .objectMapping(let error, let response):
      return "Failed to map data to a Decodable object with error \(error.localizedDescription). \nAnd with response \(response)"
    case .statusCode(let response):
      return "Status code didn't fall within the given range. \nAnd with response \(response)"
    case .requestMapping(let target):
      return "Failed to map Endpoint to a URLRequest. \nAnd with target \(target)"
    case .underlying(let error, let response):
      if let response = response {
        return "Indicates a response failed with error \(error.localizedDescription). \nAnd with response \(response)"
      } else {
        return "Indicates a response failed with error \(error.localizedDescription)"
      }
    }
  }
  
}

extension QuicksilverError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .jsonMapping:
      return "Failed to map data to JSON."
    case .stringMapping:
      return "Failed to map data to a String."
    case .objectMapping(let error, _):
      return "Failed to map data to a Decodable object with error \(error.localizedDescription)"
    case .statusCode:
      return "Status code didn't fall within the given range."
    case .requestMapping:
      return "Failed to map Endpoint to a URLRequest."
    case .underlying(let error, _):
      return error.localizedDescription
    }
  }

}
