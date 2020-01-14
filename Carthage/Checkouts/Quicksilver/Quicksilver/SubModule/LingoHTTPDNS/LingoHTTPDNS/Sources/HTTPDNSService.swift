//
//  HTTPDNSService.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// 对 HTTPDNSService 功能的接口定义，调用方可以通过实现这个接口接入自定义的 HTTPDNS 服务
public protocol HTTPDNSService {
  
  /// HTTPDNS 服务的抽象
  ///
  /// - Parameters:
  ///   - domain: 需要获取 IP 的域名 host，example: "liulishuo.com"
  ///   - maxTTL: 域名的TTL值
  ///   - response: 返回 DNS 解析结果，或者 Error
  func query(_ domain: String, maxTTL: TTL, response: @escaping (DNSRecord?, Error?) -> Void)
}

// MARK: - HTTPDNSServiceFactory

class HTTPDNSServiceFactory: HTTPDNSService {
  
  init(service: HTTPDNSService) {
    self.service = service
  }
  
  func configDefaultService(_ service: HTTPDNSService) {
    self.service = service
  }
  
  func query(_ domain: String, maxTTL: TTL, response: @escaping (DNSRecord?, Error?) -> Void) {

    func updateCompleteCache() {
      var value = [Response]()
      if let cache = queryingCompleteCache[domain] {
        value += cache
      }
      value.append(response)
      queryingCompleteCache[domain] = value
    }
    
    func callback(record: DNSRecord?) {
      querying.remove(domain)
      if let completes = queryingCompleteCache[domain] {
        completes.forEach {
          $0(record, nil)
        }
        queryingCompleteCache[domain] = nil
      }
    }
    
    if querying.contains(domain) {
      updateCompleteCache()
    } else {
      querying.insert(domain)
      updateCompleteCache()
      
      service.query(domain, maxTTL: maxTTL, response: { (record, _) in
        DispatchQueue.main.safeAsync {
          callback(record: record)
        }
      })
    }

  }
  
  // MARK: - Private
  private typealias Response = (DNSRecord?, Error?) -> Void

  private var service: HTTPDNSService
  private var querying = Set<String>()
  private var queryingCompleteCache = [String: [Response]]()
  
}
