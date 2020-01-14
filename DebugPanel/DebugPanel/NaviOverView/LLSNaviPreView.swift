//
//  LLSNaviPreView.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/8/28.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit

/// 适配留海屏
private var iphoneXBangHeight: CGFloat = 0.0

// MARK: LLSNaviPreViewProtocol
protocol LLSNaviPreViewProtocol {
  func naviPreViewNeedClose(preview: LLSNaviPreView) -> Void
  func naviPreView(preview: LLSNaviPreView, shouldPopToViewController: UIViewController) -> Void
}

class LLSNaviPreView: UIView {

  var delegate:LLSNaviPreViewProtocol!
  var viewControllers: [UIViewController]
  var coverflow: CoverflowView
  
  override init(frame: CGRect) {
    
    let iSIPhoneX = isIphoneX()
    if iSIPhoneX {
      iphoneXBangHeight = 30.0
    }
    let navigationViewController = UIApplication.shared.keyWindow?.rootViewController?.visibleNavigationViewController()
    viewControllers = navigationViewController!.viewControllers
    coverflow = CoverflowView(frame: CGRect(x: 0, y: 45, width: frame.width, height: frame.height - 45))
    super.init(frame: frame)
    
    self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    coverflow.coverSize = CGSize(width: 160, height: 430) //160*240
    coverflow.coverflowDelegate = self
    coverflow.showsHorizontalScrollIndicator = false
    coverflow.dataSource = self
    self.addSubview(coverflow)
    coverflow.reloadData()
    
    var label: UILabel = UILabel(frame: CGRect(x: 0, y: 15 + iphoneXBangHeight, width: frame.width, height: 15))
    label.backgroundColor = UIColor.clear
    label.textColor = UIColor.white
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = "左右滑动预览页面"
    self.addSubview(label)
    label = UILabel(frame: CGRect(x: 0, y: 30 + iphoneXBangHeight, width: frame.width, height: 15))
    label.backgroundColor = UIColor.clear
    label.textColor = UIColor.white
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = "双击页面进行跳转"
    self.addSubview(label)
    let button: UIButton = UIButton(type: .contactAdd)
    button.frame = CGRect(x: frame.width - 50, y: 15 + iphoneXBangHeight, width: 40, height: 40)
    UIView.animate(withDuration: 0.0) {
      button.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4).inverted()
    }
    button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
    self.addSubview(button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func closeAction() -> Void {
    self.delegate.naviPreViewNeedClose(preview: self)
  }
  
}

// MARK: implention of CoverflowViewDelegate
extension LLSNaviPreView: CoverflowViewDelegate {
  
  func coverflowViewIndexWasBroughtToFront(coverflowView: CoverflowView, index: Int) -> Void {
    
  }
  
  func coverflowViewIndexWasDoubleTapped(coverflowView: CoverflowView, index: Int) -> Void {
    self.delegate.naviPreView(preview: self, shouldPopToViewController: viewControllers[index])
  }
}

// MARK: implention of CoverflowViewDataSource
extension LLSNaviPreView: CoverflowViewDataSource {
  
  func coverflowView(coverflowView: CoverflowView, coverAtIndex: Int) -> UIView {
    var cover = coverflowView.dequeueReusableCoverView() as? NaviCoverView
    if cover == nil {
      cover = NaviCoverView(frame: CGRect(x: 0, y: 0, width: coverflow.coverSize.width, height: coverflow.coverSize.height))
    }
    
    if coverAtIndex < viewControllers.count {
      cover?.setViewController(viewControllers[coverAtIndex])
      let image = getViewControllerImage(viewControllers[coverAtIndex])
      if let image = image {
        cover?.viewControllerImageView?.image = image
      }
    }
    return cover!
  }
  
  func numberOfCoversInCoverflowView(coverflowView: CoverflowView) -> Int {
    return viewControllers.count
  }
  
  func getViewControllerImage(_ viewController: UIViewController) -> UIImage? {
    let curView = viewController.view
    return curView?.asImage()
  }
  
}
