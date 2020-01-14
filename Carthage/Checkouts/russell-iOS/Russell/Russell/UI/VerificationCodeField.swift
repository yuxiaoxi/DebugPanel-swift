//
//  VerificationCodeField.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/23.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

/// Sends `UIControl.Event.primaryActionTriggered` once the expectedLength is reached.
final class VerificationCodeField: UIControl {
  
  private var textStorage = ""
  
  var expectedLength: Int = 6 {
    didSet {
      _rebuildElements()
    }
  }
  
  // MARK: -
  
  var text: String {
    get { return textStorage }
    set {
      textStorage = newValue
      _updateElementText()
    }
  }
  
  // MARK: Rendering
  
  var elementBuilder: () -> VerificationCodeFieldElement = { DefaultVerificationCodeFieldElement() }
  
  private var elements: [VerificationCodeFieldElement] = []
  
  private func _updateElementText() {
    zip(elements, textStorage + "      ").forEach { $0.text = String($1) }
  }
  
  private func _rebuildElements() {
    subviews.forEach { $0.removeFromSuperview() }
    
    let container = UIStackView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.isUserInteractionEnabled = false
    container.axis = .horizontal
    container.spacing = 15
    container.alignment = .bottom
    addSubview(container)
    
    elements = (0..<expectedLength).map { _ in
      let element = elementBuilder()
      element.translatesAutoresizingMaskIntoConstraints = false
      container.addArrangedSubview(element)
      return element
    }
    
    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
      container.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
      bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0)
      ])
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    guard newSuperview != nil else { return }
    
    registerTapping()
    if expectedLength != elements.count {
      _rebuildElements()
    }
  }
  
  // MARK: Text Update
  
  private func _append(content: String) {
    guard textStorage.count < expectedLength else { return }
    let filtered = _filter(content: content)
    guard !filtered.isEmpty else { return }
    
    inputDelegate?.textWillChange(self)
    
    textStorage.append(filtered)
    if textStorage.count >= expectedLength {
      textStorage.removeLast(textStorage.count - expectedLength)
      sendActions(for: .primaryActionTriggered)
    }
    inputDelegate?.textDidChange(self)
    _updateElementText()
  }
  
  private func _removeLast() {
    guard !textStorage.isEmpty else { return }
    inputDelegate?.textWillChange(self)
    textStorage.removeLast()
    inputDelegate?.textDidChange(self)
    _updateElementText()
  }
  
  private func _filter(content: String) -> String {
    return content.filter({ CharacterSet.decimalDigits.contains($0.unicodeScalars.first!) })
  }
  
  private func _replace(range: Range<String.Index>, with content: String) {
    if range.lowerBound == textStorage.endIndex, range.isEmpty, textStorage.count >= expectedLength {
      return
    }
    
    let filtered = _filter(content: content)
    if filtered.isEmpty, range.isEmpty { return }
    
    inputDelegate?.textWillChange(self)
    textStorage.replaceSubrange(range, with: filtered)
    if textStorage.count >= expectedLength {
      textStorage.removeLast(textStorage.count - expectedLength)
      sendActions(for: .primaryActionTriggered)
    }
    inputDelegate?.textDidChange(self)
  }
  
  weak var inputDelegate: UITextInputDelegate?
  let tokenizer: UITextInputTokenizer = IdleTextInputTokenizer()
  
  // MARK: Responder
  
  override var canBecomeFirstResponder: Bool { return true }
  override var canResignFirstResponder: Bool { return true }
  
  @discardableResult override func becomeFirstResponder() -> Bool {
    return super.becomeFirstResponder()
  }
  
  @discardableResult override func resignFirstResponder() -> Bool {
    return super.resignFirstResponder()
  }
  
  @objc func setEditing(_ editing: Bool, animated: Bool) {
    if editing {
      becomeFirstResponder()
    } else {
      resignFirstResponder()
    }
  }
  
  // MARK: Touch Event
  override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
    var controlEvents = controlEvents
    if controlEvents.contains(.touchUpInside), target as AnyObject? !== self { // only allow self to be the target of UIControl.Event.touchUpInside
      controlEvents.remove(.touchUpInside)
    }
    super.addTarget(target, action: action, for: controlEvents)
  }
  
  private func registerTapping() {
    addTarget(self, action: #selector(_tapped(_:)), for: .touchUpInside)
  }
  
  @objc private func _tapped(_ sender: UIControl) {
    if !isFirstResponder {
      becomeFirstResponder()
    }
  }
}

// MARK: - Element

protocol VerificationCodeFieldElement: UIView {
  var text: String { get set }
}

private final class DefaultVerificationCodeFieldElement: UIView, VerificationCodeFieldElement {
  private let label = UILabel()
  private let underline = UIView()
  
  var text: String {
    get { return label.text ?? "" }
    set { label.text = newValue }
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    guard newSuperview != nil else { return }
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Russell.UI.theme.mediumFont.withSize(24)
    label.textColor = Russell.UI.theme.input.textColor
    label.textAlignment = .center
    addSubview(label)
    
    underline.translatesAutoresizingMaskIntoConstraints = false
    underline.backgroundColor = UIColor(displayP3Red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
    addSubview(underline)
    
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
      label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 30),
      
      underline.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
      underline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
      trailingAnchor.constraint(equalTo: underline.trailingAnchor, constant: 0),
      bottomAnchor.constraint(equalTo: underline.bottomAnchor, constant: 0),
      underline.widthAnchor.constraint(equalToConstant: 20),
      underline.heightAnchor.constraint(equalToConstant: 2)
      ])
  }
}

// MARK: - UITextInput

extension VerificationCodeField: UITextInput {
  
  func text(in range: UITextRange) -> String? {
    guard let range = range as? CustomTextRange else { return nil }
    guard range.startIndex >= textStorage.startIndex, range.endIndex <= textStorage.endIndex else { return nil }
    return String(textStorage[range.startIndex..<range.endIndex])
  }
  
  func replace(_ range: UITextRange, withText text: String) {
    guard let range = range as? CustomTextRange else { return }
    guard range.startIndex >= textStorage.startIndex, range.endIndex <= textStorage.endIndex else { return }
    _replace(range: range.startIndex..<range.endIndex, with: text)
  }
  
  // MARK: - Selection & Mark are NOT Supported
  
  var selectedTextRange: UITextRange? {
    get { return nil }
    //swiftlint:disable unused_setter_value
    set {}
    //swiftlint:enable unused_setter_value
  }
  var markedTextRange: UITextRange? { return nil }
  var markedTextStyle: [NSAttributedString.Key: Any]? {
    get { return nil }
    //swiftlint:disable unused_setter_value
    set {}
    //swiftlint:enable unused_setter_value
  }
  func setMarkedText(_ markedText: String?, selectedRange: NSRange) { }
  func unmarkText() {}
  
  var beginningOfDocument: UITextPosition { return CustomTextPosition(index: textStorage.startIndex) }
  var endOfDocument: UITextPosition { return CustomTextPosition(index: textStorage.endIndex) }
  
  func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
    guard let from = fromPosition as? CustomTextPosition, let to = toPosition as? CustomTextPosition else { return nil }
    guard from.index >= textStorage.startIndex, to.index <= textStorage.endIndex else { return nil }
    return CustomTextRange(startIndex: from.index, endIndex: to.index)
  }
  
  func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
    guard let position = position as? CustomTextPosition,
      position.index >= textStorage.startIndex,
      textStorage.distance(from: position.index, to: textStorage.endIndex) < offset
      else { return nil }
    
    return CustomTextPosition(index: textStorage.index(position.index, offsetBy: offset))
  }
  
  func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
    return self.position(from: position, offset: offset)
  }
  
  func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
    guard let position = position as? CustomTextPosition, let other = other as? CustomTextPosition else { return .orderedSame }
    
    if position.index > other.index {
      return .orderedDescending
    } else if position.index < other.index {
      return .orderedDescending
    } else {
      return .orderedSame
    }
  }
  
  func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
    guard let from = from as? CustomTextPosition, let to = toPosition as? CustomTextPosition else { return 0 }
    return textStorage.distance(from: from.index, to: to.index)
  }
  
  func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? { return nil }
  func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? { return nil }
  func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> UITextWritingDirection { return .leftToRight }
  func setBaseWritingDirection(_ writingDirection: UITextWritingDirection, for range: UITextRange) {}
  
  func firstRect(for range: UITextRange) -> CGRect { return .zero }
  func caretRect(for position: UITextPosition) -> CGRect { return .zero }
  func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { return [] }
  func closestPosition(to point: CGPoint) -> UITextPosition? { return nil }
  func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? { return nil}
  func characterRange(at point: CGPoint) -> UITextRange? { return nil }
}

// MARK: - UIKeyInput

extension VerificationCodeField: UIKeyInput {
  
  var hasText: Bool {
    return !textStorage.isEmpty
  }
  
  func insertText(_ text: String) {
    _append(content: text)
  }
  
  func deleteBackward() {
    guard !textStorage.isEmpty else { return }
    _removeLast()
  }
}

// MARK: - UITextInputTraits

extension VerificationCodeField: UITextInputTraits {
  var keyboardType: UIKeyboardType {
    get { return .numberPad }
    //swiftlint:disable unused_setter_value
    set {}
    //swiftlint:enable unused_setter_value
  }
  
  var textContentType: UITextContentType! {
    get {
      if #available(iOS 12.0, *) {
        return .oneTimeCode
      } else {
        return .creditCardNumber
      }
    }
    //swiftlint:disable unused_setter_value
    set {}
    //swiftlint:enable unused_setter_value
  }
}

// MARK: - UIKit Implementations

private final class IdleTextInputTokenizer: NSObject, UITextInputTokenizer {
  
  func rangeEnclosingPosition(_ position: UITextPosition, with granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextRange? {
    return nil
  }
  
  func isPosition(_ position: UITextPosition, atBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
    return false
  }
  
  func position(from position: UITextPosition, toBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextPosition? {
    return nil
  }
  
  func isPosition(_ position: UITextPosition, withinTextUnit granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
    return false
  }
}

private final class CustomTextPosition: UITextPosition {
  let index: String.Index
  required init(index: String.Index) {
    self.index = index
    super.init()
  }
}

private final class CustomTextRange: UITextRange {
  let startIndex: String.Index
  let endIndex: String.Index
  
  required init(startIndex: String.Index, endIndex: String.Index) {
    self.startIndex = startIndex
    self.endIndex = endIndex
  }
  
  override var start: UITextPosition { return CustomTextPosition(index: startIndex) }
  override var end: UITextPosition { return CustomTextPosition(index: endIndex) }
  override var isEmpty: Bool { return startIndex >= endIndex }
}
