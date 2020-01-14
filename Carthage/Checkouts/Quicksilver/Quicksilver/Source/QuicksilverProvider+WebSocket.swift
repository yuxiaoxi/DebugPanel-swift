//
//  QuicksilverProvider+WebSocket.swift
//  Quicksilver
//
//  Created by Chun on 2019/1/16.
//  Copyright © 2019 LLS iOS Team. All rights reserved.
//

import Foundation
import StarscreamPrivate

/**
 Providing Standard WebSocket close codes
 **/
public struct WebSocketCloseCode {
  
  public let rawValue: UInt16

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
  
  public static let normal = WebSocketCloseCode(rawValue: 1000)
  public static let goingAway = WebSocketCloseCode(rawValue: 1001)
  public static let protocolError = WebSocketCloseCode(rawValue: 1002)
  public static let protocolUnhandledType = WebSocketCloseCode(rawValue: 1003)
  public static let noStatusReceived = WebSocketCloseCode(rawValue: 1005)
  public static let encoding = WebSocketCloseCode(rawValue: 1007)
  public static let policyViolated = WebSocketCloseCode(rawValue: 1008)
  public static let messageTooBig = WebSocketCloseCode(rawValue: 1009)
}

public enum WebSocketErrorType: Error {
  case outputStreamWriteError //output stream error during write
  case compressionError
  case invalidSSLError //Invalid SSL certificate
  case writeTimeoutError //The socket timed out waiting to be ready to write
  case protocolError //There was an error parsing the WebSocket frames
  case upgradeError //There was an error during the HTTP upgrade
  case closeError //There was an error during the close (socket probably has been dereferenced)
  
  init(errorType: ErrorType) {
    switch errorType {
    case .outputStreamWriteError:
      self = .outputStreamWriteError
    case .compressionError:
      self = .compressionError
    case .invalidSSLError:
      self = .invalidSSLError
    case .writeTimeoutError:
      self = .writeTimeoutError
    case .protocolError:
      self = .protocolError
    case .upgradeError:
      self = .upgradeError
    case .closeError:
      self = .closeError
    }
  }

}

public struct WebSocketError: Error {
  public let type: WebSocketErrorType
  public let message: String
  public let code: Int
  
  public init(type: WebSocketErrorType, message: String, code: Int) {
    self.type = type
    self.message = message
    self.code = code
  }
  
  init(error: WSError) {
    type = WebSocketErrorType(errorType: error.type)
    message = error.message
    code = error.code
  }

}

/// WebScoket config about sub-protocols, wss certs and httpdns supports.
public struct WebSocketConfiguration {
  
  /// use http dns to improve dns. Default is `false`.
  public let useHTTPDNS: Bool
  
  public let subProtocols: [String]
  
  public let enableCompression: Bool
  
  public let eventQueue: DispatchQueue
  
  /// init method
  ///
  /// - Parameters:
  ///   - subProtocols: a list of protocols, default value is []
  ///   - useHTTPDNS: default value is false
  ///   - enableCompression: default value is true
  ///   - eventQueue: default value is main queue
  public init(subProtocols: [String] = [], useHTTPDNS: Bool = false, enableCompression: Bool = true, eventQueue: DispatchQueue = DispatchQueue.main) {
    self.subProtocols = subProtocols
    self.useHTTPDNS = useHTTPDNS
    self.enableCompression = enableCompression
    self.eventQueue = eventQueue
  }

}

/// The WebSocketEvents struct is used by the events property and manages the events for the WebSocket connection.
public struct WebSocketEvents {
  /// An event to be called when the WebSocket connection's readyState changes to .Open; this indicates that the connection is ready to send and receive data.
  public var open: () -> Void = { }
  
  /// An event to be called when a pong is received from the server.
  public var pong: (_ data: Data?) -> Void = { data in }
  
  /// An event to be called when the WebSocket disconnected with error or not
  public var disconnect: (_ error: Error?) -> Void = { error in }
  
  /// An event to be called when a data message is received from the server.
  public var dataMessage: (Data) -> Void = { message in }
  
  /// An event to be called when a string message is received from the server.
  public var stringMessage: (String) -> Void = { message in }

}

// MARK: - InnerWebSocket

class InnerWebSocket {

  var isConnected: Bool {
    if let webSocket = webSocket {
      return webSocket.isConnected
    } else {
      return false
    }
  }
  
  var event: WebSocketEvents {
    get { lock(); defer { unlock() }; return _event }
    set { lock(); defer { unlock() }; _event = newValue }
  }
  
  let eventQueue: DispatchQueue
 
  let enableCompression: Bool
  
  init(request: URLRequest, protocols: [String]?, useHTTPDNS: Bool, eventQueue: DispatchQueue, enableCompression: Bool) {
    pthread_mutex_init(&mutex, nil)

    self.eventQueue = eventQueue
    self.enableCompression = enableCompression
    
    originRequest = request

    taskQueue.async { [weak self] in
      guard let self = self else { return }
      if useHTTPDNS {
        self.initWebSocketWithHTTPDNS(request: request, protocols: protocols)
      } else {
        self.initWebSocket(request: request, protocols: protocols)
      }
    }

  }
  
  deinit {
    pthread_mutex_destroy(&mutex)
  }

  func connect() {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.connect()
    }
  }
  
  func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16) {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.disconnect(forceTimeout: forceTimeout, closeCode: closeCode)
    }
  }
  
  func write(string: String, completion: (() -> Void)?) {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.write(string: string, completion: completion)
    }
  }
  
  func write(data: Data, completion: (() -> Void)?) {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.write(data: data, completion: completion)
    }
  }
  
  func write(ping: Data, completion: (() -> Void)?) {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.write(ping: ping, completion: completion)
    }
  }
  
  func write(pong: Data, completion: (() -> Void)?) {
    taskQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocket.write(pong: pong, completion: completion)
    }
  }

  // MARK: - Private
  private let taskQueue = DispatchQueue(label: "webSocket.Quicksilver")
  
  private let originRequest: URLRequest

  private var mutex = pthread_mutex_t()

  private var webSocket: WebSocket!
  
  private var usedHTTPDNS: Bool = false
  
  private var _event = WebSocketEvents()
  
  private func initWebSocketWithHTTPDNS(request: URLRequest, protocols: [String]?) {
    if let url = request.url, let host = url.host {
      let semaphore = DispatchSemaphore(value: 0)
      var dnsResult: HTTPDNSResult?
      HTTPDNS.query(host) { (result) in
        dnsResult = result
        semaphore.signal()
      }
      _ = semaphore.wait(timeout: .distantFuture)
      if let result = dnsResult, let range = url.absoluteString.range(of: host) {
        usedHTTPDNS = true
        let newURLString = url.absoluteString.replacingCharacters(in: range, with: result.ipAddress)
        let newRequest = generateHTTPDNSRequest(originRequst: request, newURLString: newURLString, host: host)
        initWebSocket(request: newRequest, protocols: protocols)
      } else {
        initWebSocket(request: request, protocols: protocols)
      }
    } else {
      initWebSocket(request: request, protocols: protocols)
    }
  }
  
  private func generateHTTPDNSRequest(originRequst: URLRequest, newURLString: String, host: String) -> URLRequest {
    var newRequest = originRequst
    newRequest.url = URL(string: newURLString)
    newRequest.setValue(host, forHTTPHeaderField: "Host")
    newRequest.setValue(host, forHTTPHeaderField: "Origin")
    return newRequest
  }
  
  private func initWebSocket(request: URLRequest, protocols: [String]?) {
    let webSocket = WebSocket(request: request, protocols: protocols)
    webSocket.delegate = self
    webSocket.pongDelegate = self
    if usedHTTPDNS {
      webSocket.overrideTrustHostname = true
      webSocket.desiredTrustHostname = originRequest.url?.host
    }
    webSocket.callbackQueue = eventQueue
    webSocket.enableCompression = enableCompression
    self.webSocket = webSocket
  }
  
  @inline(__always) private func lock() {
    pthread_mutex_lock(&mutex)
  }
  @inline(__always) private func unlock() {
    pthread_mutex_unlock(&mutex)
  }

}

extension InnerWebSocket: WebSocketDelegate, WebSocketPongDelegate {
  
  func websocketDidConnect(socket: WebSocketClient) {
    event.open()
  }
  
  func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
    event.pong(data)
  }
  
  func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    if let error = error as? WSError {
      event.disconnect(WebSocketError(error: error))
    } else {
      event.disconnect(error)
    }
  }
  
  func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    event.stringMessage(text)
  }
  
  func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    event.dataMessage(data)
  }

}

// MARK: - QuicksilverProvider + WebSocket

extension QuicksilverProvider {
  
  open class WS {
    
    public init(request: URLRequest, configuration: WebSocketConfiguration = WebSocketConfiguration()) {
      ws = InnerWebSocket(request: request, protocols: configuration.subProtocols, useHTTPDNS: configuration.useHTTPDNS, eventQueue: configuration.eventQueue, enableCompression: configuration.enableCompression)
    }

    /// The events of the WebSocket.
    open var event: WebSocketEvents {
      get {
        return ws.event
      }
      set {
        ws.event = newValue
      }
    }

    /// WebSocket on connected status or not
    open var isConnected: Bool {
      return ws.isConnected
    }
    
    /**
     Connect to the WebSocket server on a background thread.
     */
    open func open() {
      ws.connect()
    }
    
    /**
     Disconnect from the server. I send a Close control frame to the server, then expect the server to respond with a Close control frame and close the socket from its end. I notify my event callback once the socket has been closed.
     
     If you supply a non-nil `forceTimeout`, I wait at most that long (in seconds) for the server to close the socket. After the timeout expires, I close the socket and notify my delegate.
     
     If you supply a zero (or negative) `forceTimeout`, I immediately close the socket (without sending a Close control frame) and notify my event callback.
     
     - Parameter forceTimeout: Maximum time to wait for the server to close the socket.
     - Parameter closeCode: The code to send on disconnect. The default is the normal close code for cleanly disconnecting a webSocket.
     */
    open func close(forceTimeout: TimeInterval? = nil, closeCode: WebSocketCloseCode = .normal) {
      ws.disconnect(forceTimeout: forceTimeout, closeCode: closeCode.rawValue)
    }
    
    /**
     Transmits message to the server over the WebSocket connection.
     
     - Parameter data: The Data message to be sent to the server.
     */
    open func send(_ data: Data, completion: (() -> Void)? = nil) {
      ws.write(data: data, completion: completion)
    }
    
    /**
     Transmits message to the server over the WebSocket connection.
     
     - Parameter message: The String message to be sent to the server.
     */
    open func send(_ message: String, completion: (() -> Void)? = nil) {
      ws.write(string: message, completion: completion)
    }
    
    /**
     Transmits a ping to the server over the WebSocket connection.
     
     - Parameter data: optional message The data to be sent to the server.
     */
    open func ping(_ data: Data = Data(), completion: (() -> Void)? = nil) {
      ws.write(ping: data, completion: completion)
    }
  
    // MARK: - Private
    
    private let ws: InnerWebSocket
    
  }
  
}
