//
//  CoverflowView.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/8/28.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit
import QuartzCore

/// cover的空白间限
let COVER_SPACING: CGFloat =  60.0
let SIDE_COVER_ANGLE: CGFloat = 1.4

@objc protocol CoverflowViewDelegate {
  
  @objc func coverflowViewIndexWasBroughtToFront(coverflowView: CoverflowView, index: Int) -> Void
  @objc func coverflowViewIndexWasDoubleTapped(coverflowView: CoverflowView, index: Int) -> Void
  
}

@objc protocol CoverflowViewDataSource {
  
  @objc func coverflowView(coverflowView: CoverflowView, coverAtIndex: Int) -> UIView
  @objc func numberOfCoversInCoverflowView(coverflowView: CoverflowView) -> Int
}

protocol CoverflowViewHiden {
  func animateToIndex(index: Int, animated: Bool) -> Void
  func load() -> Void
  func setup() -> Void
  func newrange() -> Void
  func setupTransforms() -> Void
  func adjustViewHeirarchy() -> Void
  
  func deplaceAlbumsFrom(start: Int, end: Int) -> Void
  func deplaceAlbumsAtIndex(cnt: Int) -> Void
  func placeAlbumsFrom(start: Int, end: Int) -> Bool
  func placeAlbumAtIndex(cnt: Int) -> Void
  
  func snapToAlbum() -> Void
}

class CoverflowView: UIScrollView {
  
  var coverViews: NSMutableArray 
  var views: NSMutableArray    // only covers view (no nulls)
  var yard: NSMutableArray     // covers ready for reuse (ie. graveyard)
  
  var origin: CGFloat
  var movingRight: Bool?
  var currentTouch: UIView?
  var deck: NSRange?
  
  var currentIndex, numberOfCovers: Int
  var margin, coverBuffer: Int?
  var currentSize: CGSize
  var spaceFromCurrent: CGFloat
  var leftTransform, rightTransform: CATransform3D?
  
  // SPEED
  var pos: Int
  var velocity: Int
  
  public var coverflowDelegate: CoverflowViewDelegate!
  public var dataSource: CoverflowViewDataSource!
  public var coverSize: CGSize
  public var coverSpacing: CGFloat
  public var coverAngle: CGFloat
  
  override init(frame: CGRect) {
    
    coverViews = NSMutableArray()
    yard = NSMutableArray()
    views = NSMutableArray()
    numberOfCovers = 0
    coverSpacing = COVER_SPACING
    coverAngle = SIDE_COVER_ANGLE
    coverSize = CGSize(width: 224, height: 224)
    spaceFromCurrent = coverSize.width / 2.4
    
    currentIndex = -1
    currentSize = frame.size
    origin = 0
    velocity = 0
    pos = 0
    super.init(frame: frame)
    load()
  }
  
  required init?(coder aDecoder: NSCoder) {
    
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touch = touches.first
    
    if touch?.view != self &&  touch?.location(in: touch?.view).y ?? 0 < coverSize.height {
      currentTouch = touch?.view
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touch = touches.first
    if touch?.view == currentTouch {
      if touch?.tapCount ?? 0 > 1 && currentIndex == coverViews.index(of: currentTouch!) {
        coverflowDelegate.coverflowViewIndexWasDoubleTapped(coverflowView: self, index: currentIndex)
      } else {
        let index = coverViews.index(of: currentTouch!)
        setContentOffset(CGPoint(x: coverSpacing * CGFloat(index), y: 0), animated: true)
      }
    }
    currentTouch = nil
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    if currentTouch != nil {
      currentTouch = nil
    }
  }
  
  func dequeueReusableCoverView() -> UIView? {
    
    guard !(yard.count < 1) else {
      return nil
    }
    
    let v = yard.lastObject as! UIView
    v.layer.transform = CATransform3DIdentity
    yard.removeLastObject()
    
    return v;
  }
  
  func coverAtIndex(index: Int) -> UIView? {
    if let view = coverViews.object(at: index) as? UIView {
      return view
    }
    return nil
  }
  
  func indexOfFrontCoverView() -> Int {
    return currentIndex
  }
  
  func bringCoverAtIndexToFront(index: Int, animated: Bool) -> Void {
    
    guard !(index == currentIndex) else {
      return
    }
    
    currentIndex = index;
    snapToAlbum()
    
    animateToIndex(index: index, animated: animated)
  }
  
  func reloadData() -> Void {
    for view in views {
      let v = view as! UIView
      v.removeFromSuperview()
    }
    yard.removeAllObjects()
    views.removeAllObjects()
    
    numberOfCovers = dataSource.numberOfCoversInCoverflowView(coverflowView:self)
    guard !(numberOfCovers < 1) else {
      return
    }
    currentSize = self.frame.size;
    margin = Int(self.frame.size.width / 2)
    coverViews = NSMutableArray(capacity: numberOfCovers)
    for _ in 0 ..< numberOfCovers {
      coverViews.add(NSNull())
    }
    let width = Int(coverSpacing) * (numberOfCovers - 1) + margin! * 2
    contentSize = CGSize(width: CGFloat(width), height: currentSize.height)
    coverBuffer = (Int) ((currentSize.width - coverSize.width) / coverSpacing) + 3
    deck = NSMakeRange(0, 0)
    movingRight = true
    
    currentSize = self.frame.size
    if currentIndex < 0 {
      currentIndex = 0
    } else if currentIndex >= numberOfCovers {
      currentIndex = numberOfCovers - 1
    }
    newrange()
    animateToIndex(index: currentIndex, animated: true)
  }
  
  func setCoverSpacing(space: CGFloat) -> Void {
    coverSpacing = space
    setupTransforms()
    setup()
    self.layoutSubviews()
  }
  
  func setCoverAngle(f: CGFloat) -> Void {
    coverAngle = f
    setupTransforms()
    setup()
  }
  
  func setCoverSize(s: CGSize) -> Void {
    coverSize = s
    spaceFromCurrent = coverSize.width/2.4
    setupTransforms()
    setup()
  }
  
}

// MARK: impletion of CoverflowViewHiden
extension CoverflowView: CoverflowViewHiden {
  
  func setupTransforms() -> Void {
    
    leftTransform = CATransform3DMakeRotation(coverAngle, 0, 1, 0)
    leftTransform = CATransform3DConcat(leftTransform!, CATransform3DMakeTranslation(-spaceFromCurrent, 0, -300))
    
    rightTransform = CATransform3DMakeRotation(-coverAngle, 0, 1, 0)
    rightTransform = CATransform3DConcat(rightTransform!, CATransform3DMakeTranslation(spaceFromCurrent, 0, -300))
  }
  
  func load() -> Void {
    
    clipsToBounds = true
    backgroundColor = UIColor.clear
    showsHorizontalScrollIndicator = true
    super.delegate = self
    origin = contentOffset.x
    setupTransforms()
    var sublayerTransform: CATransform3D = CATransform3DIdentity
    sublayerTransform.m34 = -0.001
    layer.sublayerTransform = sublayerTransform
  }
  
  func setup() -> Void {
    
    currentIndex = -1
    for view in views {
      let v = view as! UIView
      v.removeFromSuperview()
    }
    yard.removeAllObjects()
    views.removeAllObjects()
    
    numberOfCovers = dataSource.numberOfCoversInCoverflowView(coverflowView:self)
    guard !(numberOfCovers < 1) else {
      return
    }
    currentSize = self.frame.size;
    margin = Int(self.frame.size.width / 2)
    coverViews = NSMutableArray(capacity: numberOfCovers)
    for _ in 0 ..< numberOfCovers {
      coverViews.add(NSNull())
    }
    let width = Int(coverSpacing) * (numberOfCovers - 1) + margin! * 2
    contentSize = CGSize(width: CGFloat(width), height: currentSize.height)
    coverBuffer = (Int) ((currentSize.width - coverSize.width) / coverSpacing) + 3
    deck = NSMakeRange(0, 0)
    movingRight = true
    
    currentSize = self.frame.size
    currentIndex = 0
    newrange()
    animateToIndex(index: currentIndex, animated: true)
  }
  
  func deplaceAlbumsFrom(start: Int, end: Int) -> Void{
    
    guard !(start >= end) else {
      return
    }
    
    for idx in start ..< end {
      deplaceAlbumsAtIndex(cnt: idx)
    }
  }
  
  func deplaceAlbumsAtIndex(cnt: Int) -> Void{
    
    guard !(cnt >= coverViews.count) else {
      return
    }
    
    if let v = coverViews.object(at: cnt) as? UIView  {
      v.removeFromSuperview()
      views.remove(v)
      yard.add(v)
      coverViews.replaceObject(at: cnt, with: NSNull())
    }
  }
  
  func placeAlbumsFrom(start: Int, end: Int) -> Bool{
    
    guard !(start >= end) else {
      return false
    }
    
    for idx in start ... end {
      placeAlbumAtIndex(cnt: idx)
    }
    return true
  }
  
  func placeAlbumAtIndex(cnt: Int) -> Void{
    
    guard !(cnt >= coverViews.count) else {
      return
    }
    
    if coverViews.object(at: cnt) is NSNull{
      
      let cover:UIView = dataSource.coverflowView(coverflowView: self, coverAtIndex: cnt)
      coverViews.replaceObject(at: cnt, with: cover)
      var r = cover.frame
      r.origin.y = currentSize.height / 2 - (coverSize.height/2)
      r.origin.x = currentSize.width / 2 - (coverSize.width/2) + (coverSpacing) * CGFloat(cnt)
      cover.frame = r
      self.addSubview(cover)
      if cnt > currentIndex {
        cover.layer.transform = rightTransform!
        self.sendSubviewToBack(cover)
      } else {
        cover.layer.transform = leftTransform!
      }
      views.add(cover)
    }
  }
  
  func newrange() -> Void {
    let loc = deck!.location, len = deck!.length, buff = coverBuffer ?? 0
    let newLocation = currentIndex - buff < 0 ? 0 : currentIndex - buff
    let newLength = currentIndex + buff > numberOfCovers ? numberOfCovers - newLocation : currentIndex + buff - newLocation
    
    if loc == newLocation && newLength == len { return }
    
    if movingRight! {
      deplaceAlbumsFrom(start: loc, end: min(newLocation, loc+len))
      _ = placeAlbumsFrom(start: max(loc+len, newLocation), end: newLocation+newLength)
      
    } else {
      deplaceAlbumsFrom(start: max(newLength+newLocation, loc), end: loc+len)
      _ = placeAlbumsFrom(start: newLocation, end: min(loc,newLocation+newLength))
    }
    deck = NSMakeRange(newLocation, newLength);
  }
  
  func adjustViewHeirarchy() -> Void {
    var i = currentIndex - 1
    if i >= 0 {
      while i > deck!.location {
        self.sendSubviewToBack(coverViews.object(at: i) as! UIView)
        i -= 1
      }
    }
    
    i = currentIndex + 1
    
    if i < numberOfCovers - 1 {
      for idx in i ..< (deck!.location + deck!.length) {
        self.sendSubviewToBack(coverViews.object(at: idx) as! UIView)
      }
    }

    if let v = coverViews.object(at: currentIndex) as? UIView  {
      self.bringSubviewToFront(v)
    }
  }
  
  func snapToAlbum() -> Void {
  
    if let v = coverViews.object(at: currentIndex) as? UIView  {
      self.setContentOffset(CGPoint(x: v.center.x - (currentSize.width/2), y: 0), animated: true)
    } else {
      self.setContentOffset(CGPoint(x: coverSpacing * CGFloat(currentIndex), y: 0), animated: true)
    }
  }
  
  func animateToIndex(index: Int, animated: Bool) -> Void{
    let string = String(currentIndex)
    var animatedTag = animated
    if velocity > 180 { animatedTag = false }
    
    if(animatedTag){
      var speed = 0.2
    
      if velocity > 80 { speed = 0.05 }
      UIView.beginAnimations(string, context: nil)
      UIView.setAnimationDuration(speed)
      UIView.setAnimationCurve(UIView.AnimationCurve.linear)
      UIView.setAnimationBeginsFromCurrentState(true)
      UIView.setAnimationDelegate(self)
      UIView.setAnimationDidStop(#selector(animationDidStop(animationID:finished:)))
      
      for view in views {
        let v = view as! UIView
        let idx = coverViews.index(of: view)
        if idx < index {
          v.layer.transform = leftTransform!
        } else if idx > index {
          v.layer.transform = rightTransform!
        } else {
          v.layer.transform = CATransform3DIdentity
        }
      }
      
      if animatedTag {
        UIView.commitAnimations()
      } else {
        coverflowDelegate.coverflowViewIndexWasBroughtToFront(coverflowView: self, index: currentIndex)
      }
    }
  }
  
  @objc private func animationDidStop(animationID: String, finished: Bool) -> Void{
  
    if finished { adjustViewHeirarchy() }
    if finished && Int(animationID) == currentIndex {
      coverflowDelegate.coverflowViewIndexWasBroughtToFront(coverflowView: self, index: currentIndex)
    }
  }
}

// MARK: impletion UIScrollViewDelegate
extension CoverflowView: UIScrollViewDelegate {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    velocity = abs(pos - Int(scrollView.contentOffset.x))
    pos = Int(scrollView.contentOffset.x)
    movingRight = self.contentOffset.x - origin > 0 ? true : false
    origin = self.contentOffset.x;
    
    let num = CGFloat(numberOfCovers)
    let per = scrollView.contentOffset.x / (self.contentSize.width - currentSize.width);
    let ind = num * per
    var mi = ind / CGFloat(numberOfCovers/2)
    mi = 1 - mi
    mi = mi / 2
    var index = Int(ind+mi);
    index = min(max(0, index), numberOfCovers-1)
    
    guard !(index == currentIndex) else {
      return
    }
    
    currentIndex = index
    newrange()
    
    if velocity < 180 || currentIndex < 15 || currentIndex > (numberOfCovers - 16) {
      animateToIndex(index: index, animated: true)
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if !scrollView.isTracking && !scrollView.isDecelerating {
      snapToAlbum()
      adjustViewHeirarchy()
    }
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !self.isDecelerating && !decelerate {
      snapToAlbum()
      adjustViewHeirarchy()
    }
  }
}
