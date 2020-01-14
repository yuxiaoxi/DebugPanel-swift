//
//  Either.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

enum Either<Left: Decodable, Right: Decodable>: Decodable {
  case left(Left)
  case right(Right)
  
  init(from decoder: Decoder) throws {
    if let value = try? Left(from: decoder) {
      self = .left(value)
    } else if let value = try? Right(from: decoder) {
      self = .right(value)
    } else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Content is decodable neither to \(Left.self) nor to \(Right.self)"))
    }
  }
}
