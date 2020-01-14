//
//  ViewController.swift
//  QuicksilverDemo
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import UIKit
import Quicksilver

class ViewController: UIViewController {
  
  var downloader: QuicksilverProvider!
  var resumeData: Data?
  var currentDownloadTask: QuicksilverDownloadTask?
  
  var ws: QuicksilverProvider.WS?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let configuration = QuicksilverURLSessionConfiguration(useHTTPDNS: false)
    downloader = QuicksilverProvider(configuration: configuration, plugins: [NetworkLoggerPlugin(cURL: true, output: nil)])
  }
  
  @IBAction func open() {
    let test = TestViewController()
    navigationController?.pushViewController(test, animated: true)
  }

  @IBAction func download() {
    let downloadItem = TestDownloadItem(resumeData: resumeData)
    currentDownloadTask = downloader.download(downloadItem, progress: { (progress) in
      print(progress)
    }) { (result) in
      print(result)
    }
  }
  
  @IBAction func cancelDownload() {
    currentDownloadTask?.cancel(byProducingResumeData: { [weak self] (data) in
      guard let self = self else { return }
      self.resumeData = data
    })
  }
  
  @IBAction func startWebSocket() {
    let requrest = URLRequest(url: URL(string: "wss://echo.websocket.org")!)
//    let requrest = URLRequest(url: URL(string: "ws://demos.kaazing.com/echo")!)
    let ws = QuicksilverProvider.WS(request: requrest, configuration: WebSocketConfiguration(useHTTPDNS: true))
    
    ws.event.open = {
      print("ws open")
    }
    ws.event.stringMessage = { message in
      print("ws receive message \(message)")
    }
    ws.event.disconnect = { error in
      print("ws disconnet with error \(String(describing: error))")
    }
    ws.open()
    self.ws = ws
  }
  
  @IBAction func stopWebSocket() {
    ws?.close(forceTimeout: 5)
//    ws?.close(forceTimeout: 0)
//    ws?.close()
  }
  
  @IBAction func sendWebSocketMessage() {
    ws?.send("chun testing")
  }
  
}

// MARK: - Downloadable

struct TestDownloadItem: Downloadable, DownloadTargetType {
  
  var url: URL {
    return URL(string: "https://himg2.huanqiucdn.cn/attachment2010/2019/0904/07/58/20190904075818459.jpg")!
  }
  
  var resource: Downloadable {
    return self
  }
  
  var resumeData: Data?
  
  init(resumeData: Data?) {
    self.resumeData = resumeData
  }
  
}
