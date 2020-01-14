//
//  TokenStorage.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/10.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 内部的 token 管理器，主要用于管理并发的 refresh token 请求。
final class _TokenManagerInternal {
  
  private(set) var tokenStorage: TokenStorage
  private let autoRefreshThreasholdBeforeExpiring: TimeInterval
  init(tokenStorage: TokenStorage, autoRefreshThreasholdBeforeExpiring: TimeInterval = 0) {
    self.tokenStorage = tokenStorage
    self.autoRefreshThreasholdBeforeExpiring = autoRefreshThreasholdBeforeExpiring
  }
  
  private let storageLock = DispatchSemaphore(value: 1)
  
  private let refreshTaskCompletionLock = DispatchSemaphore(value: 1)
  private var refreshTaskCompletions: [(Error?) -> Void]?
}

extension _TokenManagerInternal {
  
  func updateToken(_ newToken: Token) {
    defer { storageLock.signal() }
    storageLock.wait()
    
    tokenStorage.token = newToken
  }
  
  func authorizationToken() -> String? {
    defer { storageLock.signal() }
    storageLock.wait()
    
    if let token = tokenStorage.token,
      token.expiringDate.timeIntervalSinceNow < autoRefreshThreasholdBeforeExpiring {
      DispatchQueue.global().async {
        Russell.shared?.refreshToken({ _ in })
      }
    }
    
    return tokenStorage.token?.accessToken
  }
  
  func invalidateToken() {
    defer { storageLock.signal() }
    storageLock.wait()
    
    tokenStorage.token = nil
  }
  
  func refreshToken(session: @autoclosure () -> RefreshTokenSession, completion: @escaping (Error?) -> Void) {
    defer { storageLock.signal() }
    storageLock.wait()
    guard let token = tokenStorage.token else {
      return completion(RussellError.Common.notLoggedIn)
    }
    
    defer { refreshTaskCompletionLock.signal() }
    refreshTaskCompletionLock.wait()
    
    if refreshTaskCompletions == nil {
      refreshTaskCompletions = [completion]
      session().refreshToken(from: token, completion: self.completeTokenRefresh)
    } else {
      refreshTaskCompletions?.append(completion)
    }
  }
  
  @inline(__always)
  private func completeTokenRefresh(result: RussellResult<Token>) {
    refreshTaskCompletionLock.wait()
    
    let error: Error?
    switch result {
    case .success(let value):
      storageLock.wait()
      tokenStorage.token = value
      storageLock.signal()
      error = nil
    case .failure(let err):
      error = err
    }
    
    let completions = refreshTaskCompletions
    refreshTaskCompletions = nil
    refreshTaskCompletionLock.signal()
    
    completions?.forEach { $0(error) }
  }
}
