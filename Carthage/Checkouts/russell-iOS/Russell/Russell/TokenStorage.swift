//
//  TokenStorage.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation
import Security

/// 用于存储 Token 的容器。需要外部注入。
public protocol TokenStorage: class {
  var token: Token? { get set }
}

/// Russell 默认提供的 keychain token 容器
public final class KeyChainTokenStorage: TokenStorage {
  
  public init() {}
  
  private let key = "com.liulishuo.russell-ios.2k8d2khgd0vn.token.key"
  
  private var _inMemoryCachedToken: Token?
  public var token: Token? {
    get {
      readLock.wait()
      defer { readLock.signal() }
      
      if _inMemoryCachedToken == nil {
        _inMemoryCachedToken = dataFromKeychain().flatMap { try? JSONDecoder().decode(Token.self, from: $0) }
      }
      return _inMemoryCachedToken
    }
    set {
      readLock.wait()
      defer { readLock.signal() }
      
      if updateInKeychain(newValue.flatMap { try? JSONEncoder().encode($0) }) {
        _inMemoryCachedToken = newValue
      } else {
        Logger.error("Failed to write new token into keychain!")
      }
    }
  }
  
  private let readLock = DispatchSemaphore(value: 1)
  
  private func dataFromKeychain() -> Data? {
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    
    _ = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    return result as? Data
  }
  
  private func updateInKeychain(_ data: Data?) -> Bool {
    
    let removeResult = removeStorage()
    
    guard let data = data else {
      return removeResult
    }
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }
  
  private func removeStorage() -> Bool {
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key
    ]
    
    return SecItemDelete(query as CFDictionary) == errSecSuccess
  }
}
