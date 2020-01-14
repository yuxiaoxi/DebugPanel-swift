//
//  WKWebViewController.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import WebKit

let TX_SCREEN_WIDTH = UIScreen.main.bounds.size.width
let TX_SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let TX_STATUS_BAR_HEIGHT = UIApplication.shared.statusBarFrame.size.height
let TX_NAV_BAR_HEIGHT: CGFloat = 44.0
let TX_STATUS_NAV_BAR_HEIGHT = TX_STATUS_BAR_HEIGHT + TX_NAV_BAR_HEIGHT

public class RussellWKWebViewController: UIViewController {
  private var webView: WKWebView!
  private let url: URL
  
  public required init?(url: URL) {
    self.url = url
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    webView = WKWebView(frame: CGRect(x: 0, y: TX_STATUS_NAV_BAR_HEIGHT, width: self.view.bounds.size.width, height: self.view.bounds.size.height - TX_STATUS_NAV_BAR_HEIGHT))
    webView.backgroundColor = UIColor.white
    self.view.addSubview(webView)
    self.view.addSubview(navBgView())
    //根据url创建请求
    let urlRequest = URLRequest(url: url)
    //加载请求
    webView.load(urlRequest)
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.navigationBar.isHidden = true
  }
  
  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.navigationBar.isHidden = false
  }
  
  private func navBgView() -> UIView {
    let bgView = UIView(frame: CGRect.init(x: 0, y: 0, width: TX_SCREEN_WIDTH, height: TX_STATUS_NAV_BAR_HEIGHT))
    bgView.backgroundColor = UIColor.clear
    let backButton = UIButton(frame: CGRect.init(x: 0, y: TX_STATUS_BAR_HEIGHT, width: 44.0, height: TX_NAV_BAR_HEIGHT))
    backButton.setImage(UIImage.init(named: "ic-back", in: Bundle(for: RussellWKWebViewController.self), compatibleWith: nil), for: .normal)
    backButton.addTarget(self, action: #selector(_cancel(_:)), for: .touchUpInside)
    bgView.addSubview(backButton)
    return bgView
  }
  
  @objc private func _cancel(_ sender: UIBarButtonItem) {
   self.dismiss(animated: true, completion: nil)
  }
  
}
