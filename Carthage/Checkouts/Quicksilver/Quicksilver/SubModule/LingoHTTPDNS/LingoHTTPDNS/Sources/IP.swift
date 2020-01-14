//
//  IP.swift
//  LingoHTTPDNS2
//
//  Created by Chun on 08/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

// MARK: - Public

/// 对 ipv4 和 ipv6 的抽象
///
/// - ipv4: ipv4 的地址
/// - ipv6: ipv6 的地址
public enum IP: Equatable, CustomStringConvertible {
  case ipv4(address: String)
  case ipv6(address: String)
  
  /// 获取实际 IP 地址
  public var address: String {
    switch self {
    case .ipv4(let address):
      return address
    case .ipv6(let address):
      return address
    }
  }
  
  public static func == (lhs: IP, rhs: IP) -> Bool {
    return lhs.address == rhs.address
  }

  public var description: String {
    switch self {
    case .ipv4(let address):
      return "IPV4: \(address)"
    case .ipv6(let address):
      return "IPV6: \(address)"
    }
  }
  
  /// 获取当前用户设备的 IP，当获取失败时，返回 nil
  public static var currentIP: IP? {
    if let ip = try? getIPV4() {
      return ip
    } else {
      return try? getIPV6()
    }
  }

}

// MARK: - Internal

private let _ipModificationQueue = DispatchQueue(label: "com.liulishuo.LingoHTTPDNS.ipModification", attributes: .concurrent)

private var _previousIP: IP?

private var previousIP: IP? {
  get {
    return _ipModificationQueue.sync { _previousIP }
  }
  set {
    let workItem = DispatchWorkItem(flags: .barrier) {
      _previousIP = newValue
    }
    _ipModificationQueue.async(execute: workItem)
  }
}

func isNetworkChanged() -> (networkChanged: Bool, currentIP: IP?) {
  var changed: (Bool, IP?) = (true, nil)
  if let ip = IP.currentIP {
    if let previousIP = previousIP, previousIP == ip {
      changed = (false, ip)
    } else {
      previousIP = ip
      changed = (true, ip)
    }
  }
  return changed
}

// MARK: - Private

private let IPV4_SOCKECT_ADDRESS = "8.8.8.8"
private let IPV6_SOCKECT_ADDRESS = "2001:4860:4860::8888"
private let SOCKET_ADDRESS_PORT = 53

extension IP {

  private static func constructIPError(errorCode: Int = -1, description: String? = nil) -> NSError {
    return NSError(domain: "com.liulishuo.httpDNS", code: errorCode, userInfo: [NSLocalizedDescriptionKey: description ?? "Unknown"])
  }
  
  private static func getIPV4() throws -> IP {
    var err: Int32 = 0
    let sock = socket(AF_INET, SOCK_DGRAM, 0)
    if sock < 0 {
      err = errno
      throw constructIPError(errorCode: Int(err))
    }
    
    var addr = sockaddr_in()
    memset(&addr, 0, MemoryLayout.size(ofValue: addr))
    inet_pton(AF_INET, IPV4_SOCKECT_ADDRESS, &addr.sin_addr)
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = in_port_t(UInt16(SOCKET_ADDRESS_PORT).bigEndian)
    
    err = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        return connect(sock, $0, UInt32(MemoryLayout<sockaddr_in>.size))
      }
    }
    
    if err < 0 {
      err = errno
    }
    
    var localAddr = sockaddr_in()
    err = withUnsafeMutablePointer(to: &localAddr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        return getsockname(sock, $0, &len)
      }
    }
    
    close(sock)
    
    if err != 0 {
      throw constructIPError(errorCode: Int(err))
    }
    
    var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
    inet_ntop(AF_INET, &localAddr.sin_addr, &buf, socklen_t(INET_ADDRSTRLEN))
    
    let string = String(cString: buf)
    if string.isValidIPV4() {
      return IP.ipv4(address: string)
    } else {
      throw constructIPError(description: "\(string) is not a valid ipv4 ip address")
    }
  }
  
  private static func getIPV6() throws -> IP {
    var err: Int32 = 0
    let sock = socket(AF_INET6, SOCK_DGRAM, 0)
    if sock < 0 {
      err = errno
      throw constructIPError(errorCode: Int(err))
    }
    
    var addr = sockaddr_in6()
    memset(&addr, 0, MemoryLayout.size(ofValue: addr))
    inet_pton(AF_INET6, IPV6_SOCKECT_ADDRESS, &addr.sin6_addr)
    addr.sin6_family = sa_family_t(AF_INET6)
    addr.sin6_port = in_port_t(UInt16(SOCKET_ADDRESS_PORT).bigEndian)
    
    err = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        return connect(sock, $0, UInt32(MemoryLayout<sockaddr_in6>.size))
      }
    }
    
    if err < 0 {
      err = errno
    }
    
    var localAddr = sockaddr_in6()
    err = withUnsafeMutablePointer(to: &localAddr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        var len = socklen_t(MemoryLayout<sockaddr_in6>.size)
        return getsockname(sock, $0, &len)
      }
    }
    
    close(sock)
    
    if err != 0 {
      throw constructIPError(errorCode: Int(err))
    }
    
    var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
    inet_ntop(AF_INET6, &localAddr.sin6_addr, &buf, socklen_t(INET6_ADDRSTRLEN))
    
    let string = String(cString: buf)
    if string.isValidIPV6() {
      return IP.ipv6(address: string)
    } else {
      throw constructIPError(description: "\(string) is not a valid ipv6 ip address")
    }
  }
  
}

extension String {
  
  func isValidIPV4() -> Bool {
    var address = in_addr()
    guard inet_pton(AF_INET, self, &address) == 1 else {
      return false
    }
    return self != "0.0.0.0"
  }
  
  func isValidIPV6() -> Bool {
    var address = in6_addr()
    guard inet_pton(AF_INET6, self, &address) == 1 else {
      return false
    }
    return self != "::"
  }
  
  func isValidIPAddress() -> Bool {
    return isValidIPV4() || isValidIPV6()
  }

}
