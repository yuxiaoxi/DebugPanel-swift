//
//  DNSPodEnterpriseHTTPDNSService.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import DesPrivate

/// 提供 DNSPod 企业级 HTTPDNS 服务
public class DNSPodEnterpriseHTTPDNSService: HTTPDNSService {
  let des = Des(DNSEnterpriseKey.data(using: String.Encoding.utf8))

  public func query(_ domain: String, maxTTL: TTL, response: @escaping (DNSRecord?, Error?) -> Void) {
    if let encrypt = encrypt(domain), let url = URL(string: getDNSPodEnterpriseRequestURLString(encrypt)) {
      var request = URLRequest(url: url)
      request.timeoutInterval = 5
      request.cachePolicy = .reloadIgnoringLocalCacheData
      let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, requestResponse, _) in
        if let requestResponse = requestResponse as? HTTPURLResponse, let data = data, requestResponse.statusCode == 200 {
          let raw = self?.decrypt(data)
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
  
  fileprivate func decrypt(_ raw: Data) -> String? {
    if let string = String(data: raw, encoding: String.Encoding.utf8), let enc = Hex.decode(string), let data = des?.decrpyt(enc) {
      return String(data: data, encoding: String.Encoding.utf8)
    } else {
      return nil
    }
  }
  
  fileprivate func encrypt(_ domain: String) -> String? {
    if let data = des?.encrypt(domain.data(using: String.Encoding.utf8)) {
      return Hex.encode(data)
    } else {
      return nil
    }
  }
}

// MARK: - DNSPod Enterprise Utilities

/// DNSPod Enterprise account Info
let DNSEnterpriseKey = "3JIF11OL"
let DNSEnterpriseID = "548"

func getDNSPodEnterpriseRequestURLString(_ dn: String) -> String {
  return "http://\(DNSPOD_SERVER_IP)/d?ttl=1&dn=\(dn)&id=\(DNSEnterpriseID)"
}
