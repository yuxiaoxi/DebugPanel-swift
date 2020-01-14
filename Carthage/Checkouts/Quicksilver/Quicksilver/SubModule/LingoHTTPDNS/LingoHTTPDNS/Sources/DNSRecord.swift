//
//  Domain.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

public typealias TTL = TimeInterval

/// DNS 解析结果的抽象
public struct DNSRecord {
  public let ip: IP
  public let ttl: TTL
  
  public init(ip: IP, ttl: TTL) {
    self.ip = ip
    self.ttl = ttl
  }

}
