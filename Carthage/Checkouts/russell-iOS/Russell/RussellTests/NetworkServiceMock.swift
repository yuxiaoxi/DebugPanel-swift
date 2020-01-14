//
//  NetworkServiceMock.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

@testable import Russell

final class MockCancellable: Cancellable {
  func cancel() {}
}

final class NetworkServiceMock: NetworkService {
  
  var json: JSONFile?
  
  @discardableResult func request<Value>(api: API<Value>, extraErrorMapping: [RussellError.ErrorMapping], decoder: @escaping (Data) throws -> Value, completion: @escaping (RussellResult<Value>) -> Void) -> Cancellable {
    guard let json = json else {
      return MockCancellable()
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      if let response: Value = json.loadData().flatMap({ try? decoder($0) }) {
        completion(.success(response))
      } else {
        completion(.failure(RussellError.Common.networkError))
      }
    }
    
    return MockCancellable()
  }
}
