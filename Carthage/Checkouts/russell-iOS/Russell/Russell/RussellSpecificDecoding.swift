//
//  RussellSpecificDecoding.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/4/8.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
  
  func russell_decodeStringUInt64(forKey key: Key) throws -> UInt64 {
    
    let integerString = try decode(String.self, forKey: key)
    if let integer = UInt64(integerString) {
      return integer
    } else {
      throw DecodingError.typeMismatch(UInt64.self, DecodingError.Context(codingPath: [key], debugDescription: "Expecting string which could be converted to UInt64"))
    }
  }
  
  func russell_decodeDate(forKey key: Key) throws -> Date {

    if let timeInterval = try? decode(Double.self, forKey: key) {
      return Date(timeIntervalSince1970: timeInterval)
    } else if let timeString = try? decode(String.self, forKey: key), let timeInterval = TimeInterval(timeString) {
      return Date(timeIntervalSince1970: timeInterval)
    } else {
      throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: [key], debugDescription: "Expected double, or string which could convert to double"))
    }
  }
  
  func russell_decodeUSecDate(forKey key: Key) throws -> Date {
    
    if let timeInterval = try? decode(Double.self, forKey: key) {
      return Date(timeIntervalSince1970: timeInterval / 100000)
    } else if let timeString = try? decode(String.self, forKey: key), let timeInterval = TimeInterval(timeString) {
      return Date(timeIntervalSince1970: timeInterval / 100000)
    } else {
      throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: [key], debugDescription: "Expected double, or string which could convert to double"))
    }
  }
  
  func russell_decodeURLIfPresent(forKey key: Key) throws -> URL? {
    let string = try decodeIfPresent(String.self, forKey: key)
    return string.flatMap(URL.init(string:))
  }
}

struct StringCodingKey: CodingKey {
  let stringValue: String
  
  init?(stringValue: String) {
    self.stringValue = stringValue
  }
  
  var intValue: Int? { return nil}
  
  init?(intValue: Int) {
    return nil
  }
}
