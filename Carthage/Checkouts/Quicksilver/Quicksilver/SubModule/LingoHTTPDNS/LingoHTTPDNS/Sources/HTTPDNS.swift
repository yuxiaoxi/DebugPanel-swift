//
//  HTTPDNS.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

public typealias HTTPDNSResponse = (HTTPDNSResult?) -> Void

/// HTTPDNS 是 LingoHTTPDNS 的核心类，用于通过 Domain 获得对应的 IP。
public class HTTPDNS {
  
  /// 对 domain 进行同步 HTTPDNS 查询服务
  /// LingoHTTPDNS 同步查询服务仅仅会读 cache，如果 cache 中没有记录，将会返回 nil。
  /// HTTPDNS 内部服务是异步执行，且不应该认为是完全可靠的(可能出现 HTTPDNS 提供商出现异常等不可预期的情况)。
  /// 外部在获取 HTTPDNSResult 失败时，应该尝试直接使用域名做具体的接口请求，而不是直接抛出异常。
  ///
  /// - Parameters:
  ///   - domain: 需要查询的 domain 信息，需要是标准的一级域名，如 "liulishuo.com" 或者 "apple.com"
  ///   - maxTTL: 域名解析记录在 HTTPDNS 缓存中最大存留时间，默认是 300, 一般情况下，使用默认值
  /// - Returns: 返回 HTTPDNSResult，可以得到对应的 IP 等信息。如果获取失败，返回为空。
  public static func query(_ domain: String, maxTTL: TTL = 300) -> HTTPDNSResult? {
    return HTTPDNS.shared.query(domain: domain, maxTTL: maxTTL)
  }
  
  /// 参考 query(_ domain: String, maxTTL: TTL = 300)
  /// 该方法提供 HTTPDNS Query 的异步服务, 和同步方法不同的是，异步查询服务在缓存中没有记录时，会从 HTTPDNS 服务器查询并返回
  public static func query(_ domain: String, maxTTL: TTL = 300, complete: @escaping (HTTPDNSResult?) -> Void) {
    HTTPDNS.shared.query(domain: domain, maxTTL: maxTTL, complete: complete)
  }
  
  /// 通过 IP 地址从 HTTPDNS 缓存中反查域名信息
  ///
  /// - Parameter ip: ip 地址
  /// - Returns: 域名信息，当 cache 不存在时，返回 nil
  public static func getOriginDomain(ipAddress: String) -> String? {
    return HTTPDNS.shared.getOriginDomain(ipAddress: ipAddress)
  }
  
  /// 尝试向 HTTPDNS 提交某一个 domain 的 IP Cache 出现错误
  /// 当调用方发现通过 IP 直接请求出错，且 HTTPDNSResult 返回标记为来自缓存时，可以执行这个方法，去除 HTTPDNS 内部的潜在无效缓存信息
  /// - Parameter domain: 域名
  public static func setDomainCacheFailed(_ domain: String) {
    HTTPDNS.shared.setDomainCacheFailed(domain)
  }
  
  /// 向 HTTPDNS 注入自定义的 HTTPDNS 服务
  ///
  /// - Parameter httpDNSService: 实现自己的 HTTPDNS 服务。默认使用 DNSPod 的企业级接口。
  public static func configDefaultHTTPDNSService(httpDNSService: HTTPDNSService) {
    HTTPDNS.shared.configDefaultHTTPDNSService(httpDNSService: httpDNSService)
  }
  
  // MARK: - Internal
  
  static let shared = HTTPDNS()
  
  private let lockQueue = DispatchQueue(label: "com.liulishuo.httpDNS", attributes: .concurrent)
  private var dnsServive = HTTPDNSServiceFactory(service: DNSPodEnterpriseHTTPDNSService())
  
  private var hostToIpMappedCache = [String: Set<String>]()
  private var dnsRecordCache = [String: HTTPDNSResult]()
  
  func query(domain: String, maxTTL: TTL) -> HTTPDNSResult? {
    let shouldQuery = shouldQueryDomain()
    if shouldQuery.shouldQuery {
      defer {
        tryFetchDNSFromDNSService(domain: domain, maxTTL: maxTTL) // 尝试从 HTTPDNS 服务触发更新 DNS
      }
      if shouldQuery.networkChanged { // 用户网络变更后，DNS 缓存失效。
        invalidAllDNSCache()
        return nil
      } else {
        return getDNSResultFromCache(domain: domain)
      }
    } else {
      return nil
    }
  }
  
  func query(domain: String, maxTTL: TTL = 300, complete: @escaping (HTTPDNSResult?) -> Void) {
    let shouldQuery = shouldQueryDomain()
    if shouldQuery.shouldQuery {
      if shouldQuery.networkChanged {
        invalidAllDNSCache()
      }
      if let result = getDNSResultFromCache(domain: domain) {
        complete(result)
      } else {
        tryFetchDNSFromDNSService(domain: domain, maxTTL: maxTTL, comeplete: { (result) in
          complete(result)
        })
      }
    } else {
      complete(nil)
    }
  }
  
  func tryFetchDNSFromDNSService(domain: String, maxTTL: TTL, comeplete: ((HTTPDNSResult?) -> Void)? = nil) {
    DispatchQueue.main.safeAsync {
      self.dnsServive.query(domain, maxTTL: maxTTL) { (record, _) in
        if let record = record {
          let httpDNSResult = self.constructHTTPDNSResult(record: record)
          self.cacheDNSResult(result: httpDNSResult, with: domain, complete: {
            comeplete?(httpDNSResult)
          })
        } else {
          comeplete?(nil)
        }
      }
    }
  }
  
  func getOriginDomain(ipAddress: String) -> String? {
    var domain: String?
    
    lockQueue.sync {
       domain = self.hostToIpMappedCache.filter { (_, value) -> Bool in
        return value.filter { (result) -> Bool in
          return result == ipAddress
        }.count > 0
      }.first?.key
    }
    
    return domain
  }
  
  func setDomainCacheFailed(_ domain: String, complete: (() -> Void)? = nil) {
    let resetTask = DispatchWorkItem(flags: .barrier) {
      self.dnsRecordCache[domain] = nil
      DispatchQueue.main.safeAsync {
        complete?()
      }
    }
    lockQueue.async(execute: resetTask)
  }
  
  func configDefaultHTTPDNSService(httpDNSService: HTTPDNSService) {
    dnsServive.configDefaultService(httpDNSService)
  }
  
  func shouldQueryDomain() -> (shouldQuery: Bool, networkChanged: Bool) {
    let result = isNetworkChanged()
    if let ip = result.currentIP, case .ipv4 = ip {
      return (true, result.networkChanged)
    } else {
      return (false, result.networkChanged)
    }
  }
  
  func invalidAllDNSCache(complete: (() -> Void)? = nil) {
    let removeTask = DispatchWorkItem(flags: .barrier) {
      self.dnsRecordCache.removeAll()
      DispatchQueue.main.safeAsync {
        complete?()
      }
    }
    lockQueue.async(execute: removeTask)
  }
  
  func getDNSResultFromCache(domain: String) -> HTTPDNSResult? {
    var result: HTTPDNSResult?
    
    lockQueue.sync {
      result = self.dnsRecordCache[domain]
    }
    
    if let result = result, result.timeout <= getSecondTimestamp() {
      setDomainCacheFailed(domain)
      return nil
    } else {
      return result
    }
  }
  
  func cacheDNSResult(result: HTTPDNSResult, with domain: String, complete: (() -> Void)? = nil) {
    let updateTask = DispatchWorkItem(flags: .barrier) {
      
      var newCacheResult = result
      newCacheResult.fromCached = true
      self.dnsRecordCache[domain] = newCacheResult
      
      if let cacheResults = self.hostToIpMappedCache[domain] {
        var set = cacheResults
        set.update(with: newCacheResult.ipAddress)
        self.hostToIpMappedCache[domain] = set
      } else {
        self.hostToIpMappedCache[domain] = Set<String>([newCacheResult.ipAddress])
      }
      DispatchQueue.main.safeAsync {
        complete?()
      }
    }
    lockQueue.async(execute: updateTask)
  }
  
  func constructHTTPDNSResult(record: DNSRecord, fromCached: Bool = false) -> HTTPDNSResult {
    let timeout = getSecondTimestamp() + record.ttl * 0.75
    let result = HTTPDNSResult(dnsRecord: record, fromCached: fromCached, timeout: timeout)
    return result
  }

}

extension HTTPDNS {
  
  private func getSecondTimestamp() -> TimeInterval {
    return Date().timeIntervalSince1970
  }
}

extension DispatchQueue {
  
  func safeAsync(_ block: @escaping () -> Void) {
    if self === DispatchQueue.main && Thread.isMainThread {
      block()
    } else {
      async { block() }
    }
  }

}
