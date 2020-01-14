//
//  ReviewBoundMobileViewController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

private extension ReviewBoundMobileViewController {
  
  final class PageTracker {
    
    enum Source: Int {
      case strong
      case weak
      case newBinding
    }
    
    private var currentSource: Source?
    
    func enter(source: Source?) -> (DataTracker) -> Void {
      return { tracker in
        
        if self.currentSource == .newBinding { // newBinding 的打点时机为 换绑手机成功回调。之后会立刻触发 reload content 并在 reload 结束后打结果点 (同为 page track)，此时仅需要记录结果而不是重复打点
          self.currentSource = source
        } else if source == nil { // 入参 source == nil 表示换绑手机流程取消，此时需要打之前的状态点
          tracker.enter(page: "user_profile_detail", properties: self.currentSource.map { ["source": $0.rawValue] })
        } else { // 其他情况下，打入参点，并标记 currentSource
          tracker.enter(page: "user_profile_detail", properties: source.map { ["source": $0.rawValue] })
          self.currentSource = source
        }
      }
    }
  }
}

final class ReviewBoundMobileViewController: UIViewController, HeadsUpDisplayable, _Trackable {
  
  private let pageTracker = PageTracker()
  
  @objc private func _rebind(_ sender: UIButton) {
    _bind(isRebinding: true)
  }
  
  private var _currentRealNameInfo: RealNameInfo?
  
  private func _bind(isRebinding: Bool) {
    tracker?.action(actionName: "click_update_mobile", properties: nil)
    
    var tracking = BindMobileTracking(source: .userCenter, currentMobileStatus: .none)
    if isRebinding {
      if _currentRealNameInfo?.isWeakBinding == true {
        tracking.currentMobileStatus = .weak
      } else {
        tracking.currentMobileStatus = .strong
      }
    }
    
    let configuration = BindMobileConfiguration(privacyInfo: nil, isRebinding: isRebinding, isExpired: false, requiresToken: true, session: _currentRealNameInfo?.session)
    Russell.UI._bindMobile(in: .navigation(navigationController!), configuration: configuration, tracking: tracking) { (error) in
      if error == nil {
        self.tracker.map(self.pageTracker.enter(source: .newBinding))
        self._reloadContent()
      } else {
        self.tracker.map(self.pageTracker.enter(source: nil))
      }
    }
  }
  
  // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = _UILocalizedString(for: "Review-Bound-Mobile-Title")
    
    hidesBottomBarWhenPushed = true
    
    view.backgroundColor = .white
    edgesForExtendedLayout = []
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tracker?.enter(page: "user_profile_detail", properties: nil)
    _reloadContentIfNeeded()
  }
  
  // MARK: - Builder
  
  private var contentInitialized = false
  
  private func _reloadContentIfNeeded() {
    guard !contentInitialized else { return }
    _reloadContent()
    contentInitialized = true
  }
  
  private func _reloadContent() {
    headsUpDisplay?.show()
    Russell.shared?.fetchRealNameInfo(checksExpirationDate: false, completion: { [weak self] (result) in
      guard let self = self else { return }
      
      self.headsUpDisplay?.dismiss()
      switch result {
      case .success(let result):
        self._currentRealNameInfo = result
        if let mobile = result.mobile, !mobile.isEmpty, let message = result.message {
          self.tracker.map(self.pageTracker.enter(source: result.isWeakBinding == true ? .weak : .strong))
          self._rebuildContent(mobile: mobile, comment: message)
        } else {
          self._bind(isRebinding: false)
        }
      case .failure(let error):
        self.headsUpDisplay?.showError(error.localizedDescription)
        self.tracker.map(self.pageTracker.enter(source: nil))
      }
    })
  }
  
  private func _cleanContent() {
    view.subviews.forEach { $0.removeFromSuperview() }
  }
  
  private func _rebuildContent(mobile: String, comment: String) {
    _cleanContent()
    
    let icon = UIImageView(image: UIImage(named: "ic-mobile", in: Bundle(for: ReviewBoundMobileViewController.self), compatibleWith: nil))
    icon.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(icon)
    
    let mobileLabel = UILabel()
    mobileLabel.translatesAutoresizingMaskIntoConstraints = false
    mobileLabel.font = Russell.UI.theme.font.withSize(16)
    mobileLabel.textColor = Russell.UI.theme.textColor.titleColor
    mobileLabel.textAlignment = .center
    mobileLabel.numberOfLines = 0
    mobileLabel.text = String(format: _UISafeLocalizedString(for: "Review-Bound-Mobile-Your-Mobile-Format"), mobile)
    view.addSubview(mobileLabel)
    
    let commentLabel = UILabel()
    commentLabel.translatesAutoresizingMaskIntoConstraints = false
    commentLabel.font = Russell.UI.theme.font.withSize(12)
    commentLabel.textColor = Russell.UI.theme.textColor.contentColor
    commentLabel.textAlignment = .center
    commentLabel.numberOfLines = 0
    commentLabel.text = comment
    view.addSubview(commentLabel)
    
    let rebindButton = _bindButton(title: _UISafeLocalizedString(for: "Review-Bound-Mobile-Rebind-Button"))
    rebindButton.addTarget(self, action: #selector(_rebind(_:)), for: .touchUpInside)
    view.addSubview(rebindButton)
    
    NSLayoutConstraint.activate([
      icon.topAnchor.constraint(equalTo: view.topAnchor, constant: 36),
      icon.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
      
      mobileLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
      mobileLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 25),
      view.trailingAnchor.constraint(equalTo: mobileLabel.trailingAnchor, constant: 50),
      
      commentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
      commentLabel.topAnchor.constraint(equalTo: mobileLabel.bottomAnchor, constant: 10),
      view.trailingAnchor.constraint(equalTo: commentLabel.trailingAnchor, constant: 50),
      
      rebindButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Russell.UI.sidePadding),
      rebindButton.topAnchor.constraint(equalTo: commentLabel.bottomAnchor, constant: 20),
      view.trailingAnchor.constraint(equalTo: rebindButton.trailingAnchor, constant: Russell.UI.sidePadding),
      rebindButton.heightAnchor.constraint(equalToConstant: 44)
      ])
  }
  
  private func _bindButton(title: String) -> UIButton {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.cornerRadius = Russell.UI.theme.button.radius
    switch Russell.UI.theme.button.style {
      
    case .default:
      button.layer.borderWidth = 1
      button.layer.borderColor = Russell.UI.theme.tintColor.cgColor
      button.setTitleColor(Russell.UI.theme.tintColor, for: .normal)
      
    case .allFill:
      button.setTitleColor(.white, for: .normal)
      button.backgroundColor = Russell.UI.theme.tintColor
    }
    
    button.titleLabel?.font = Russell.UI.theme.button.font
    button.setTitle(title, for: .normal)
    return button
  }
}
