//
//  DNSPodHTTPDNSService.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// 提供 DNSPod 一般用户 HTTPDNS 服务
public class DNSPodHTTPDNSService: HTTPDNSService {
  public func query(_ domain: String, maxTTL: TTL, response: @escaping (DNSRecord?, Error?) -> Void) {
    if let url = URL(string: getDNSPodRequestURLString(domain)) {
      var request = URLRequest(url: url)
      request.timeoutInterval = 5
      request.cachePolicy = .reloadIgnoringLocalCacheData
      let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, requestResponse, _) in
        if let requestResponse = requestResponse as? HTTPURLResponse, let data = data, requestResponse.statusCode == 200 {
          let raw = String(data: data, encoding: String.Encoding.utf8)
          let record = raw.flatMap { dnsPodParse($0, ttl: maxTTL)}
          response(record, nil)
        } else {
          response(nil, nil)
        }
      })
      task.resume()
    } else {
      response(nil, nil)
    }
  }
}

// MARK: - DNSPod Utilities

let DNSPOD_SERVER_IP = "119.29.29.29"

func getDNSPodRequestURLString(_ domain: String) -> String {
  return "http://\(DNSPOD_SERVER_IP)/d?ttl=1&dn=\(domain)"
}

// standard raw response string like: `220.181.57.216;111.13.101.208,146`
func dnsPodParse(_ raw: String, ttl: TTL?) -> DNSRecord? {
  guard raw.count > 0 else {
    return nil
  }
  
  let strArray = raw.components(separatedBy: ",")
  guard strArray.count == 2 else {
    return nil
  }
  
  let ipStr = strArray[0]
  let fetchedTTL = TimeInterval(strArray[1]) ?? 0
  guard fetchedTTL > 0 else {
    return nil
  }
  
  let ipAddress: String
  let ipList = ipStr.components(separatedBy: ";")
  if ipList.count > 0 {
    ipAddress = ipList[0]
  } else {
    ipAddress = ipStr
  }
  if ipAddress.isValidIPV4() {
    if let ttl = ttl, fetchedTTL > ttl {
      return DNSRecord(ip: IP.ipv4(address: ipAddress), ttl: ttl)
    } else {
      return DNSRecord(ip: IP.ipv4(address: ipAddress), ttl: fetchedTTL)
    }
  } else {
    return nil
  }

}
