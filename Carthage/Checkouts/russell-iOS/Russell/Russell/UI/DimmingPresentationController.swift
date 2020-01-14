//
//  DimmingPresentationController.swift
//  Lingome
//
//  Created by Johnny on 4/5/16.
//  Copyright © 2016 LLS iOS Team. All rights reserved.
//

import UIKit

protocol DimmingPresentationControllerPresentedViewController: NSObjectProtocol {
  func frameOfPresentedView(in containerView: UIView) -> CGRect
}

class DimmingPresentationController: UIPresentationController {
  
  var backgroundColor = UIColor.black.withAlphaComponent(0.7)
  lazy var dimmingView: UIView = {
    let view = UIView(frame: self.containerView!.bounds)
    view.backgroundColor = self.backgroundColor
    view.alpha = 0.0 //initial value for animation. DO NOT change it
    return view
  }()
  
  var canTapToDismiss: Bool = false
  private lazy var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedDimmingView))
  
  var dismissCompletion: (() -> Void)?
  
  // MARK: Action
  
  @objc func tappedDimmingView() {
    if canTapToDismiss {
      presentingViewController.dismiss(animated: true, completion: nil)
    }
  }
  
  override func presentationTransitionWillBegin() {
    guard let containerView = containerView else { return }
    
    // Add the dimming view and the presented view to the heirarchy
    containerView.addSubview(dimmingView)
    dimmingView.frame = containerView.bounds
    dimmingView.addGestureRecognizer(tapGestureRecognizer)
    
    // Fade in the dimming view alongside the transition
    if let transitionCoordinator = presentingViewController.transitionCoordinator {
      transitionCoordinator.animate(alongsideTransition: {(_: UIViewControllerTransitionCoordinatorContext!) -> Void in
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 1.0
      }, completion: nil)
    }
  }
  
  override func presentationTransitionDidEnd(_ completed: Bool) {
    // If the presentation didn't complete, remove the dimming view
    if !completed {
      self.dimmingView.removeFromSuperview()
    }
  }
  
  override func dismissalTransitionWillBegin() {
    // Fade out the dimming view alongside the transition
    if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
      transitionCoordinator.animate(alongsideTransition: { _ in
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        self.dimmingView.alpha = 0.0
      }, completion: nil)
    }
  }
  
  override func dismissalTransitionDidEnd(_ completed: Bool) {
    // If the dismissal completed, remove the dimming view
    if completed {
      self.dimmingView.removeFromSuperview()
      dismissCompletion?()
    }
  }
  
  override var frameOfPresentedViewInContainerView: CGRect {
    if let containerView = containerView,
      let viewController = presentedViewController as? DimmingPresentationControllerPresentedViewController {
      return viewController.frameOfPresentedView(in: containerView)
    }
    
    return super.frameOfPresentedViewInContainerView
  }
  
  // MARK: - UIContentContainer protocol
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    guard let containerView = containerView else { return }
    
    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.frame = containerView.bounds
    }, completion: nil)
  }
  
}
