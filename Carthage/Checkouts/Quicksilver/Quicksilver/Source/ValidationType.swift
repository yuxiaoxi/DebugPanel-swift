//
//  ValidationType.swift
//  Quicksilver
//
//  Created by Chun on 13/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// Represents the status codes to validate through Alamofire.
public enum ValidationType {
  
  /// Validate success codes (only 2xx).
  case successCodes
  
  /// Validate success codes and redirection codes (only 2xx and 3xx).
  case successAndRedirectCodes
  
  /// Validate only the given status codes.
  case customCodes([Int])
  
  /// The list of HTTP status codes to validate.
  var statusCodes: [Int] {
    switch self {
    case .successCodes:
      return Array(200..<300)
    case .successAndRedirectCodes:
      return Array(200..<400)
    case .customCodes(let codes):
      return codes
    }
  }
}

extension ValidationType: Equatable {
  
  public static func == (lhs: ValidationType, rhs: ValidationType) -> Bool {
    switch (lhs, rhs) {
    case (.successCodes, .successCodes),
         (.successAndRedirectCodes, .successAndRedirectCodes):
      return true
    case (.customCodes(let c1), .customCodes(let c2)):
      return c1 == c2
    default:
      return false
    }
  }

}
