//
//  UploadTargetType.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/21.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

// MARK: - UploadTargetType

public struct MultipartformData {
  
  let data: AFMultipartFormData
  
  /**
   Appends the HTTP header `Content-Disposition: file; filename=#{generated filename}; name=#{name}"` and `Content-Type: #{generated mimeType}`, followed by the encoded file data and the multipart form boundary.
   
   The filename and MIME type for this data in the form will be automatically generated, using the last path component of the `fileURL` and system associated MIME type for the `fileURL` extension, respectively.
   
   @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
   @param name The name to be associated with the specified data. This parameter must not be `nil`.
   */
  public func appendPart(withFileURL fileURL: URL, name: String) throws {
    try data.appendPart(withFileURL: fileURL, name: name)
  }
  
  /**
   Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
   
   @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
   @param name The name to be associated with the specified data. This parameter must not be `nil`.
   @param fileName The file name to be used in the `Content-Disposition` header. This parameter must not be `nil`.
   @param mimeType The declared MIME type of the file data. This parameter must not be `nil`.
   */
  public func appendPart(withFileURL fileURL: URL, name: String, fileName: String, mimeType: String) throws {
    try data.appendPart(withFileURL: fileURL, name: name, fileName: fileName, mimeType: mimeType)
  }
  
  /**
   Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the data from the input stream and the multipart form boundary.
   
   @param inputStream The input stream to be appended to the form data
   @param name The name to be associated with the specified input stream. This parameter must not be `nil`.
   @param fileName The filename to be associated with the specified input stream. This parameter must not be `nil`.
   @param length The length of the specified input stream in bytes.
   @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
   */
  public func appendPart(with inputStream: InputStream?, name: String, fileName: String, length: Int64, mimeType: String) {
    data.appendPart(with: inputStream, name: name, fileName: fileName, length: length, mimeType: mimeType)
  }
  
  /**
   Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
   
   @param data The data to be encoded and appended to the form data.
   @param name The name to be associated with the specified data. This parameter must not be `nil`.
   @param fileName The filename to be associated with the specified data. This parameter must not be `nil`.
   @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
   */
  public func appendPart(withFileData data: Data, name: String, fileName: String, mimeType: String) {
    self.data.appendPart(withFileData: data, name: name, fileName: fileName, mimeType: mimeType)
  }
  
  /**
   Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.
   
   @param data The data to be encoded and appended to the form data.
   @param name The name to be associated with the specified data. This parameter must not be `nil`.
   */
  public func appendPart(withForm data: Data, name: String) {
    self.data.appendPart(withForm: data, name: name)
  }
  
  /**
   Appends HTTP headers, followed by the encoded data and the multipart form boundary.
   
   @param headers The HTTP headers to be appended to the form data.
   @param body The data to be encoded and appended to the form data. This parameter must not be `nil`.
   */
  public func appendPart(withHeaders headers: [String: String]?, body: Data) {
    data.appendPart(withHeaders: headers, body: body)
  }
  
  /**
   Throttles request bandwidth by limiting the packet size and adding a delay for each chunk read from the upload stream.
   
   When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, there is no definite way to distinguish between a 3G, EDGE, or LTE connection over `NSURLConnection`. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.
   
   @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 16kb.
   @param delay Duration of delay each time a packet is read. By default, no delay is set.
   */
  public func throttleBandwidth(withPacketSize numberOfBytes: Int, delay: TimeInterval) {
    data.throttleBandwidth(withPacketSize: numberOfBytes, delay: delay)
  }
  
}

/// - multipartForm->Void  Creates an `NSMutableURLRequest` object with the specified HTTP method and URLString, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2 A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `MultipartformData` protocol.
public enum UploadType {
  case file(URL)
  case data(Data)
  case multipartForm(constructingBody: (MultipartformData)->Void)
}

public protocol UploadTargetType: TargetType {
  /// upload url for uploading
  var uploadURL: URL { get }
  
  var uploadType: UploadType { get }
}

public extension UploadTargetType {
  
  /// Default value is `.successCodes`.
  var validation: ValidationType {
    return .successCodes
  }
  
  /// Default value is `POST` on UploadTargetType
  var method: HTTPMethod {
    return .post
  }
  
  /// Default value is nil.
  var parameters: [String: Any]? {
    return nil
  }
  
  var headers: [String: String]? {
    return nil
  }
  
  var fullRequestURL: URL {
    return uploadURL
  }
  
  var priority: Float {
    return 0.5
  }

  var timeoutInterval: TimeInterval? {
    return nil
  }
}
