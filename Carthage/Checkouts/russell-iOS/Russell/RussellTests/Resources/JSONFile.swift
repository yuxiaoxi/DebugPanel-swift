//
//  JSONFile.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

protocol JSONSource {
  func loadData() -> Data?
}

extension JSONSource where Self: RawRepresentable, Self.RawValue == String {
  
  func loadData() -> Data? {
    guard let url = Bundle(for: NetworkServiceMock.self).url(forResource: rawValue, withExtension: "json") else {
      return nil
    }
    return try? Data(contentsOf: url)
  }
}

enum JSONFile: String, JSONSource {
  
  case smsChallenge
  
  case captchaChallenge
  
  case loginSuccessResult
  
  case refreshTokenResult
  
  case refreshTokenResultCompatibility
  
  case empty
  
  case confirmRegistrationChallengeExtraParam = "confirmRegistrationChallenge1"
  
  case confirmRegistrationChallengeNoExtraParam = "confirmRegistrationChallenge2"
  
  func load<T: Decodable>() -> T? {
    guard
      let data = loadData(),
      let result = try? JSONDecoder().decode(T.self, from: data)
      else { return nil }
    
    return result
  }
}
