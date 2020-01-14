//
//  RefreshTokenSpec.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

private final class RFNetworkServiceMock: NetworkService {
  
  private(set) var requestCounter = 0
  
  @discardableResult func request<Value>(api: API<Value>, extraErrorMapping: [RussellError.ErrorMapping], decoder: @escaping (Data) throws -> Value, completion: @escaping (RussellResult<Value>) -> Void) -> Cancellable {
    
    requestCounter += 1
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      if let response: Value = JSONFile.refreshTokenResult.loadData().flatMap({ try? decoder($0) }) {
        completion(.success(response))
      } else {
        completion(.failure(RussellError.Common.networkError))
      }
    }
    
    return MockCancellable()
  }
}

final class RefreshTokenSpec: QuickSpec {
  
  override func spec() {
    
    describe("refresh token") {
      
      var tokenStorage: TokenStorage!
      var networkService: RFNetworkServiceMock!
      var service: Russell!
      
      beforeEach {
        tokenStorage = MemoryTokenStorage()
        tokenStorage.token = Token(accessToken: "ttt", refreshToken: "rrr", expiringDate: .distantFuture)
        networkService = RFNetworkServiceMock()
        service = Russell(networkService: networkService, poolID: "", deviceID: "ddd", tokenManager: _TokenManagerInternal(tokenStorage: tokenStorage), dataTracker: DummyDataTracer(), privacyAction: { _ in })
      }
      
      afterEach {
        service.currentSession?.invalidate()
        service = nil
      }
      
      it("should update token") {
        
        let expectation = XCTestExpectation(description: "refresh token")
        service.refreshToken { _ in
          expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
        
        expect(tokenStorage.token?.accessToken).toEventually(equal("jwt"), timeout: 2)
      }
      
      context("batch refresh") {
        
        let count = Int(arc4random_uniform(3) + 2)
        var results: [Bool] = []
        
        beforeEach {
          results = Array(repeating: false, count: count)
          
          let lock = DispatchSemaphore(value: 1)
          for index in 0..<count {
            service.refreshToken { _ in
              lock.wait()
              results[index] = true
              lock.signal()
            }
          }
        }
        
        it("should all complete") {
          expect(results).toEventually(equal(Array(repeating: true, count: count)))
        }
        
        it("should send request only once") {
          expect(networkService.requestCounter).toEventually(equal(1), timeout: 2)
        }
      }
    }
  }
}

final class TokenUpgradeCompatibilitySpec: QuickSpec {
  override func spec() {
    
    describe("token upgrade") {
      
      it("should be compatible with old storage") {
        expect(JSONFile.refreshTokenResultCompatibility.load() as TokenRefreshResponse?).toNot(beNil())
      }
      
      it("should decode new storage") {
        expect(JSONFile.refreshTokenResult.load() as TokenRefreshResponse?).toNot(beNil())
      }
    }
  }
}
