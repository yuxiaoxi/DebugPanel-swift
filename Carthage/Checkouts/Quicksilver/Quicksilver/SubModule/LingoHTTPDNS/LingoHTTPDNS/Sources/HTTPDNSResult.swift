//
//  HTTPDNSResult.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// 每一次通过 LingoHTTPDNS 做 DNS 查询时，在正确的情况下，会返回 `HTTPDNSResult`。
public struct HTTPDNSResult: Hashable {
  
  public let dnsRecord: DNSRecord
  
  /// 获得当前的查询记录是否来自 LingoHTTPDNS Service 的缓存
  /// 当调用方发现结果来自缓存并且请求失败时，可以尝试通过 HTTPDNS.setDomainCacheFailed 标记缓存失效。
  public internal(set) var fromCached: Bool

  public func hash(into hasher: inout Hasher) {
    hasher.combine(dnsRecord.ip.address)
  }

  public static func == (lhs: HTTPDNSResult, rhs: HTTPDNSResult) -> Bool {
    return lhs.dnsRecord.ip.address == rhs.dnsRecord.ip.address
  }
  
  public var ip: IP {
    return dnsRecord.ip
  }
  
  public var ipAddress: String {
    return dnsRecord.ip.address
  }
  
  let timeout: TimeInterval
}
