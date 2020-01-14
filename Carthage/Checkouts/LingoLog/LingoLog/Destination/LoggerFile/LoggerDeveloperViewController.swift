//
//  BeehiveLogViewController.swift
//  LingoFoundation
//
//  Created by apple on 27/04/2017.
//  Copyright © 2017 LLS iOS Team. All rights reserved.
//

import UIKit

// MARK: - LoggerDeveloperViewController

class LoggerDeveloperViewController: UITableViewController {
  
  fileprivate let cellReuseIdentifier = "UITableViewCell"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "LingoLogger"
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) {
      cell.textLabel?.text = "Log Files"
      return cell
    } else {
      return UITableViewCell()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let logViewController = LoggerViewController(style: .plain)
    navigationController?.pushViewController(logViewController, animated: true)
  }
}

// MARK: - BeehiveLogViewController

class LoggerViewController: UITableViewController {
  
  fileprivate var logPaths = [String]()
  fileprivate let cellReuseIdentifier = "UITableViewCell"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    logPaths = LoggerFileDestination.getAllAvailableLogFilePaths()
    
    title = "Log"
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    
    loadShareBarButtonItem()
  }
  
  fileprivate func loadShareBarButtonItem() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShareBarButtonItemTapped))
  }
  
  @objc func handleShareBarButtonItemTapped() {
    let shareTitle = "Log Report"
    var activityItems = [Any]()
    activityItems.append(shareTitle)
    logPaths.forEach { str in
      let url = URL(fileURLWithPath: str)
      activityItems.append(url)
    }
    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    navigationController?.present(activityViewController, animated: true, completion: nil)
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return logPaths.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) {
      cell.textLabel?.text = (logPaths[indexPath.row] as NSString).lastPathComponent
      cell.textLabel?.adjustsFontSizeToFitWidth = true
      return cell
    } else {
      return UITableViewCell()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let logReviewViewController = LoggerReviewViewController(with: logPaths[indexPath.row])
    navigationController?.pushViewController(logReviewViewController, animated: true)
  }
}

// MARK: - LoggerReviewViewController

class LoggerReviewViewController: UIViewController, UIWebViewDelegate {
  
  fileprivate let logPathURL: URL
  
  init(with logPath: String) {
    self.logPathURL = URL(fileURLWithPath: logPath)
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = logPathURL.lastPathComponent
    
    loadShareBarButtonItem()
    loadWebView()
  }
  
  fileprivate func loadWebView() {
    let webView = UIWebView(frame: CGRect.zero)
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.backgroundColor = UIColor.white
    webView.delegate = self
    view.addSubview(webView)
    
    var constraits = [NSLayoutConstraint]()
    constraits += NSLayoutConstraint.constraints(withVisualFormat: "|-0-[webView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["webView": webView])
    constraits += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["webView": webView])
    NSLayoutConstraint.activate(constraits)
    
    if let data = try? Data(contentsOf: logPathURL) {
      webView.load(data, mimeType: "text/plain", textEncodingName: "UTF-8", baseURL: logPathURL)
    }
  }
  
  fileprivate func loadShareBarButtonItem() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShareBarButtonItemTapped))
  }
  
  @objc func handleShareBarButtonItemTapped() {
    let shareTitle = "Log Report"
    let activityViewController = UIActivityViewController(activityItems: [shareTitle, logPathURL], applicationActivities: nil)
    navigationController?.present(activityViewController, animated: true, completion: nil)
  }
  
  func webViewDidFinishLoad(_ webView: UIWebView) {
    let webViewContentSize = webView.scrollView.contentSize
    webView.scrollView.scrollRectToVisible(CGRect(x: 0, y: webViewContentSize.height - webView.bounds.size.height, width: webView.bounds.size.width, height: webView.bounds.size.height), animated: true)
  }
  
  func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
    print(error)
  }
  
}
