//
//  Network.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/11.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

typealias RussellResult<T> = Result<T, Error>

// MARK: - API Wrapper

/// Russell 内部使用的 HTTP API 抽象
struct API<Value> {
  let method: HTTPMethod
  let path: String
  var body: [String: Any]?
  var extraHeaders: [String: String]?
  var baseURL: URL = URL(fileURLWithPath: "/")
  var timeoutForRequest: TimeInterval?
  
  init(method: HTTPMethod, path: String, body: [String: Any]?, extraHeaders: [String: String]? = nil) {
    self.method = method
    self.path = path
    self.body = body
    self.extraHeaders = extraHeaders
  }
  
  init(method: HTTPMethod, path: String, body: [String: Any]?, extraHeaders: [String: String]? = nil, timeoutForRequest: TimeInterval? = nil) {
    self.init(method: method, path: path, body: body, extraHeaders: extraHeaders)
    self.timeoutForRequest = timeoutForRequest
  }
}

extension API: DataTargetType {
  
  var headers: [String: String]? {
    let tracePart1 = UInt64.random(in: 0...UInt64.max)
    let tracePart2 = UInt64.random(in: 0...UInt64.max)
    let span = UInt64.random(in: 0...UInt64.max)
    
    var headers = extraHeaders ?? [:]
    headers["X-B3-Traceid"] = String(format: "%llx%llx", tracePart1, tracePart2)
    headers["X-B3-Spanid"] = String(format: "%llx", span)
    return headers
  }
  
  var parameters: [String: Any]? { return body }
  
  var timeoutInterval: TimeInterval? {
    return timeoutForRequest
  }
}

protocol Cancellable {
  func cancel()
}

private final class TaskWrapper: Cancellable, CustomStringConvertible {
  
  private let task: QuicksilverDataTask
  init(task: QuicksilverDataTask) {
    self.task = task
  }
  
  func cancel() {
    task.cancel()
  }
  
  var description: String {
    return String(describing: task)
  }
}

extension URLSessionTask: Cancellable {}

// MARK: - Network Service

/// Russell 内部使用的简易网络服务
protocol NetworkService {
  
  @discardableResult func request<Value>(api: API<Value>, extraErrorMapping: [RussellError.ErrorMapping], decoder: @escaping (Data) throws -> Value, completion: @escaping (RussellResult<Value>) -> Void) -> Cancellable
}

final class Network: NetworkService {
  
  private let networkProvider: QuicksilverProvider
  
  private let host: URL
  init(host: URL, networkProvider: QuicksilverProvider) {
    self.host = host
    self.networkProvider = networkProvider
  }
  
  convenience init(configuration: Russell.URLConfiguration, deviceID: String, poolID: String, appID: String) {
    let plugins: [PluginType] = [
      CachePolicyPlugin(),
      DefaultParametersPlugin(deviceID: deviceID, poolID: poolID, appID: appID),
      NetworkLoggerPlugin(cURL: true, output: { string in
        RussellLogger.debug(string)
      })
    ]
    
    let sessionConfiguration = QuicksilverURLSessionConfiguration(useHTTPDNS: configuration.usesHTTPDNS)
    sessionConfiguration.urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    sessionConfiguration.urlSessionConfiguration.urlCache = nil
    let networkProvider = QuicksilverProvider(configuration: sessionConfiguration, plugins: plugins, callbackQueue: .main)
    
    self.init(host: configuration.host, networkProvider: networkProvider)
  }
  
  @discardableResult func request<Value>(api: API<Value>, extraErrorMapping: [RussellError.ErrorMapping] = [], decoder: @escaping (Data) throws -> Value, completion: @escaping (RussellResult<Value>) -> Void) -> Cancellable {
    
    func translateError(response: Response?, rawError: Error?) -> Error {
      guard let response = response else {
        return RussellError.Common.networkError
      }
      
      let serverError = try? JSONDecoder().decode(ServerError.self, from: response.data)
      return RussellError.translate(statusCode: response.statusCode, serverError: serverError, rawError: rawError, extraErrorMappings: extraErrorMapping)
    }
    
    let task = networkProvider.request(update(api: api)) { (result) in
      switch result {
        
      case .success(let response):
        let data = response.data
        do {
          try completion(.success(decoder(data)))
        } catch {
          Logger.debug("Unable to decode \(Response.self) from response:\n\(String.init(data: data, encoding: .utf8) ?? "nil")")
          Monitor.trackError(.decodingFailure, description: "Unable to decode \(Response.self): \(error)")
          completion(.failure(RussellError.Common.clientInternalError))
        }
        
      case .failure(let error):
        switch error {
          
        case .underlying(let error as NSError, _) where error.code == NSURLErrorCancelled:
          completion(.failure(RussellError.Common.canceled))
          
        case .underlying(let rawError, let response):
          completion(.failure(translateError(response: response, rawError: rawError)))
          
        case .objectMapping(let rawError, let response):
          completion(.failure(translateError(response: response, rawError: rawError)))
          
        case .statusCode(let response),
             .stringMapping(let response),
             .jsonMapping(let response):
          completion(.failure(translateError(response: response, rawError: nil)))
          
        default:
          completion(.failure(RussellError.Common.unknown))
        }
      }
    }
    
    task.resume()
    return TaskWrapper(task: task)
  }
  
  private func update<Value>(api: API<Value>) -> API<Value> {
    var newAPI = api
    newAPI.baseURL = host
    
    return newAPI
  }
}

extension Network {
  
  static func headers(forToken token: String) -> [String: String] {
    return [
      "Authorization": "Bearer \(token)"
    ]
  }
}

// MARK: - Signature

import CommonCrypto

enum SignatureGenerator {
  /// 用给定的参数生成部分请求里需要的签名校验。详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2)中对 sig 的描述。
  static func signatureFrom(poolID: String, timestampInSec: Int, extra: String) -> String {
    let step1: String = sha1(from: poolID + String(timestampInSec))
    return sha1(from: extra + step1)
  }
  
  @inline(__always)
  private static func sha1(from string: String) -> String {
    
    return string.withCString { input in
      var digest = [UInt8](repeating: 0, count: numericCast(CC_SHA1_DIGEST_LENGTH))
      CC_SHA1(UnsafeRawPointer(input), numericCast(string.count), &digest)
      let hexBytes = digest.map { String(format: "%02hhx", $0) }
      return hexBytes.joined()
    }
  }
}

struct ServerError: Decodable {
  let code: Int
  let message: String?
  let detail: String?
  
  enum CodingKeys: String, CodingKey {
    case code
    case message = "error"
    case detail
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    if let code = try? container.decode(Int.self, forKey: .code) {
      self.code = code
    } else if let codeString = try? container.decode(String.self, forKey: .code), let code = Int(codeString) {
      self.code = code
    } else {
      throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: [CodingKeys.code], debugDescription: "Expected int, or string which could convert to int"))
    }
    
    message = try container.decodeIfPresent(String.self, forKey: .message)
    detail = try container.decodeIfPresent(String.self, forKey: .detail)
  }
}
