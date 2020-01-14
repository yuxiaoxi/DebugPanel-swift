//
//  QuicksilverURLSessionConfiguration.swift
//  Quicksilver
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import AFNetworkingPrivate

public class QuicksilverURLSessionConfiguration {

  /// use http dns to improve dns. Default is `true`.
  public var useHTTPDNS: Bool

  /// local check certificate when send https request. Default is `false`.
  public let httpsCertificateLocalVerify: Bool

  /// certificates bundle. If you set `httpsCertificateLocalVerify` to true, this value should not be nil.
  public let certificatesBundle: Bundle?
  
  /// encodes request parameters config, default is json
  public let requestParamaterEncodeType: RequestParameterEncodeType
  
  /// use stub for testing, default is never. And Only support Data Target Type.
  public let stub: StubBehavior

  /// urlSessionConfiguration, default value is `URLSessionConfiguration.default`
  public var urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
  
  public init(useHTTPDNS: Bool = true, httpsCertificateLocalVerify: Bool = false, certificatesBundle: Bundle? = nil, requestParamaterEncodeType: RequestParameterEncodeType = .json(JSONSerialization.WritingOptions(rawValue: 0)), stub: StubBehavior = .never) {
    self.useHTTPDNS = useHTTPDNS
    self.certificatesBundle = certificatesBundle
    self.httpsCertificateLocalVerify = httpsCertificateLocalVerify
    self.stub = stub
    self.requestParamaterEncodeType = requestParamaterEncodeType
  }

}

/// encodes request parameters
///
/// - json: encodes parameters as JSON, setting the `Content-Type` of the encoded request to `application/json`
/// - xPlist: encodes parameters as plist, setting the `Content-Type` of the encoded request to `application/x-plist`
public enum RequestParameterEncodeType {
  case json(JSONSerialization.WritingOptions)
  case xPlist(PropertyListSerialization.PropertyListFormat, PropertyListSerialization.WriteOptions)
}

extension RequestParameterEncodeType {
  var requestSerialization: AFHTTPRequestSerializer {
    switch self {
    case .json(let writingOptions):
      return AFJSONRequestSerializer(writingOptions: writingOptions)
    case .xPlist(let listFormat, let writeOptions):
      return AFPropertyListRequestSerializer(format: listFormat, writeOptions: writeOptions)
    }
  }
}
