//
//  QuicksilverProvider+AFNetworking.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/21.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

private func convertResponseToResult(_ response: HTTPURLResponse?, request: URLRequest?, data: Data?, error: Error?, with target: TargetType) -> Result<Response, QuicksilverError> {
  if let response = response, error == nil {
    let customResponse = Response(statusCode: response.statusCode, data: data ?? Data(), request: request, response: response)
    if target.validation.statusCodes.contains(response.statusCode) {
      return .success(customResponse)
    } else {
      let error = QuicksilverError.statusCode(customResponse)
      return .failure(error)
    }
  } else {
    let statusCode = response?.statusCode ?? 400 // client error with the case about response is nil
    let customResponse = Response(statusCode: statusCode, data: data ?? Data(), request: request, response: response)
    let error = QuicksilverError.underlying(error ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "Request failed with unknown Error"]), customResponse)
    return .failure(error)
  }
}

// MARK: - AFNetworking & Request

extension QuicksilverProvider {
  
  func sendRequest(_ target: TargetType, request: URLRequest, callbackQueue: DispatchQueue?, progress: ProgressBlock?, originHost: String?, completion: @escaping Completion) -> TaskToken {
    
    let plugins = self.plugins
    plugins.forEach { $0.willSend(request, target: target) }
    
    var taskToken: TaskToken!
    
    let completionHandler: (URLResponse?, Any?, Error?) -> Void = { response, responseObject, error in
      let httpURLResponse = response as? HTTPURLResponse
      let data = (responseObject ?? nil) as? Data
      if let originHost = originHost, error != nil {
        HTTPDNS.setDomainCacheFailed(originHost)
      }
      let result = convertResponseToResult(httpURLResponse, request: request, data: data, error: error, with: target)
      plugins.forEach { $0.didReceive(result, target: target) }
      
      safeAsync(queue: callbackQueue) {
        taskToken.finished()
        completion(result)
      }
    }
    
    let task: URLSessionTask
    if target as? DataTargetType != nil {
      task = af_dataTask(with: request, completionHandler: completionHandler)
    } else if let downloadTarget = target as? DownloadTargetType {
      task = af_downloadTask(with: request, downloadTarget: downloadTarget, callbackQueue: callbackQueue, progress: progress, completionHandler: completionHandler)
    } else if let uploadTarget = target as? UploadTargetType {
      task = af_uploadTask(with: request, target: uploadTarget, callbackQueue: callbackQueue, progress: progress, completionHandler: completionHandler)
    } else {
      fatalError("\(target) not support.")
    }
    
    task.priority = target.priority
    taskToken = TaskToken(sessionTask: task)
    taskToken.resume()
    return taskToken
  }
}

// MARK: - DataTargetType

extension QuicksilverProvider {
  
  private func af_dataTask(with request: URLRequest, completionHandler: @escaping (URLResponse?, Any?, Error?) -> Void) -> URLSessionDataTask {
    return sessionManager.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: completionHandler)
  }
  
}

// MARK: - UploadTargetType

extension QuicksilverProvider {
  
  private func af_uploadTask(with request: URLRequest, target: UploadTargetType, callbackQueue: DispatchQueue?, progress: ProgressBlock?, completionHandler: @escaping (URLResponse?, Any?, Error?) -> Void) -> URLSessionUploadTask {
    
    let progressClusre: ((Progress) -> Void) = { _progress in
      let sendProgress: () -> Void = {
        progress?(_progress)
      }
      safeAsync(queue: callbackQueue) {
        sendProgress()
      }
    }
    
    switch target.uploadType {
    case .data(let data):
      return sessionManager.uploadTask(with: request, from: data, progress: progressClusre, completionHandler: completionHandler)
    case .file(let fileURL):
      return sessionManager.uploadTask(with: request, fromFile: fileURL, progress: progressClusre, completionHandler: completionHandler)
    case .multipartForm:
      return sessionManager.uploadTask(with: request, from: nil, progress: progress, completionHandler: completionHandler)
    }
  }
  
}

// MARK: - DownloadTargetType

extension QuicksilverProvider {
  
  private func af_downloadTask(with request: URLRequest, downloadTarget: DownloadTargetType, callbackQueue: DispatchQueue?, progress: ProgressBlock?, completionHandler: @escaping (URLResponse?, Any?, Error?) -> Void) -> URLSessionDownloadTask {
    let progressClusre: ((Progress) -> Void) = { _progress in
      let sendProgress: () -> Void = {
        progress?(_progress)
      }
      safeAsync(queue: callbackQueue) {
        sendProgress()
      }
    }
    
    if let resumeData = downloadTarget.resource.resumeData {
      return sessionManager.downloadTask(withResumeData: resumeData, progress: progressClusre, destination: downloadTarget.downloadDestination, completionHandler: { (response, url, error) in
        let data = url?.path.data(using: .utf8)
        completionHandler(response, data, error)
      })
    } else {
      return sessionManager.downloadTask(with: request, progress: progressClusre, destination: downloadTarget.downloadDestination) { (response, url, error) in
        let data = url?.path.data(using: .utf8)
        completionHandler(response, data, error)
      }
    }
  }

}
