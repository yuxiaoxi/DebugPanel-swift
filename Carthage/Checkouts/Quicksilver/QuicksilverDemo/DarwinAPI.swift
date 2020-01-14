//
//  DarwinAPI.swift
//  QuicksilverDemo
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import Quicksilver

var token: String? = "dad558000a510136d0c00ad1ff22b9f9"

public struct DarwinAPIRequestPlugin: PluginType {
  
  public var extraParameters: [String: Any]? {
    var paramaters =  ["appId": "darwin",
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "sDeviceId": UIDevice.current.identifierForVendor?.uuidString ?? ""]
    if let token = token {
      paramaters["token"] = token
    }
    return paramaters
  }
  
}

public protocol DawinAPI: DataTargetType { }
extension DawinAPI {
  public var baseURL: URL {
    return URL(string: "https://staging-neo.llsapp.com/api/v1")!
  }
}

public enum DarwinUserInfoRouter: DawinAPI, AccessTokenAuthorizable {
  
  case fetchUserInfo
  case logout

  public var path: String {
    switch self {
    case .fetchUserInfo:
      return "users"
      
    case .logout:
      return "sessions"
    }
  }
  
  public var method: HTTPMethod {
    switch self {
    case .fetchUserInfo:
      return .get
      
    case .logout:
      return .delete
    }
  }
  
  public var parameters: [String: Any]? {
    return nil
  }
  
  public var authorizationType: AuthorizationType {
    return .bearer
  }
  
  public var sampleResponse: SampleResponseClosure? {
    return {
      return SampleResponse.networkResponse(200, "chun".data(using: .utf8)!)
    }
  }
  
}

public enum DarwinLoginRouter: DawinAPI {
 
  case fetchSessionsCode(mobileNumber: String)
  case loginWithCode(mobileNumber: String, code: String)

  public var path: String {
    switch self {
    case .fetchSessionsCode:
      return "sessions/code"
      
    case .loginWithCode:
      return "sessions/signin_with_code"
    }
  }
  
  public var method: HTTPMethod {
    switch self {
    case .fetchSessionsCode, .loginWithCode:
      return .post
    }
  }
  
  public var parameters: [String: Any]? {
    switch self {
    case .fetchSessionsCode(mobileNumber: let number):
      return ["mobile": number]
      
    case .loginWithCode(mobileNumber: let number, code: let code):
      return ["mobile": number, "code": code]
    }
  }
}
