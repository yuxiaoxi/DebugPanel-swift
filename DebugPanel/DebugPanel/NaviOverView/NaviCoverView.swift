//
//  NaviCoverView.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/8/29.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import QuartzCore
import UIKit

/// 预览图片的宽、高
let kCoverWidth = 160
let kCoverHeight = 240

class NaviCoverView: UIView {
  var viewController: UIViewController?
  private(set) var viewControllerImageView: UIImageView?
  
  private var contentView: UITextView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    isOpaque = false
    backgroundColor = UIColor.clear
    //self.clipsToBounds = YES;
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    viewControllerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat(kCoverWidth), height: CGFloat(kCoverHeight)))
    viewControllerImageView?.backgroundColor = UIColor.black
    viewControllerImageView?.layer.borderColor = UIColor.gray.cgColor
    viewControllerImageView?.layer.borderWidth = 2
    self.addSubview(viewControllerImageView!)
    
    contentView = UITextView(frame: CGRect(x: 0, y: CGFloat(kCoverHeight + 5), width: CGFloat(kCoverWidth), height: 30))
    contentView?.backgroundColor = UIColor.clear
    contentView?.font = UIFont(name: "Helvetica", size: 15.0)
    contentView?.textColor = UIColor.white
    contentView?.isEditable = false
    contentView?.textAlignment = .center
    self.addSubview(contentView!)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setViewController(_ viewController: UIViewController?) -> Void {
    
    self.viewController = viewController
    var title = viewController?.title
    if (title?.count ?? 0) < 1 {
      title = viewController?.navigationItem.title
    }
    if (title?.count ?? 0) < 1 {
      title = "[no title]"
    }
    contentView?.text = "\(title ?? "")"
  }
}
