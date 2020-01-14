//
//  AreaCodePickerViewController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/23.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

final class AreaCodePickerViewController: UIViewController {
  
  private let initialSelectetDial: String
  required init(selectedDial: String) {
    initialSelectetDial = selectedDial
    super.init(nibName: nil, bundle: nil)
    
    modalPresentationStyle = .custom
    transitioningDelegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  weak var delegate: AreaCodePickerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    
    let bar = _buildBar()
    view.addSubview(bar)
    
    let picker = _buildPicker()
    view.addSubview(picker)
    
    NSLayoutConstraint.activate([
      bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      bar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
      view.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 0),
      bar.heightAnchor.constraint(equalToConstant: 40),
      
      picker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      picker.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 0),
      view.trailingAnchor.constraint(equalTo: picker.trailingAnchor, constant: 0)
//      view.bottomAnchor.constraint(equalTo: picker.bottomAnchor, constant: 0)
      ])
  }
  
  private func _selected(row: Int) {
    guard row < AreaCodeLoader.shared.areaCodes.endIndex else { return }
    delegate?.updateSelection(AreaCodeLoader.shared.areaCodes[row].dialCode)
  }
  
  @objc private func _search(_ sender: UIBarButtonItem) {
    guard let delegate = delegate else { return }
    dismiss(animated: true) {
      delegate.presentAreaCodeSearcher()
    }
  }
  
  @objc private func _done(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  private func _buildBar() -> UIToolbar {
    let bar = UIToolbar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    
    let searchItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(_search(_:)))
    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(_done(_:)))
    bar.items = [searchItem, space, done]
    return bar
  }
  
  private func _buildPicker() -> UIPickerView {
    let picker = UIPickerView()
    picker.backgroundColor = .white
    picker.translatesAutoresizingMaskIntoConstraints = false
    picker.dataSource = self
    picker.delegate = self
    picker.reloadAllComponents()
    picker.selectRow(
      AreaCodeLoader.shared.dialAreaCodeMap[initialSelectetDial] ?? 0,
      inComponent: 0,
      animated: false)
    return picker
  }
}

extension AreaCodePickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return AreaCodeLoader.shared.areaCodes.count
  }
  
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    let rowView: AreaCodePickerRow
    if let reused = view as? AreaCodePickerRow {
      rowView = reused
    } else {
      rowView = AreaCodePickerRow()
    }
    
    rowView.prepareForReuse()
    
    if row < AreaCodeLoader.shared.areaCodes.endIndex {
      rowView.update(area: AreaCodeLoader.shared.areaCodes[row])
    }
    
    return rowView
  }
  
  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 44
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    _selected(row: row)
  }
}

// MARK: - Picker Row

private final class AreaCodePickerRow: UIView {
  
  private lazy var left = self._buildLabel(color: UIColor(displayP3Red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1))
  private lazy var right = self._buildLabel(color: UIColor(displayP3Red: 155 / 255, green: 155 / 255, blue: 155 / 255, alpha: 1))
  
  func update(area: AreaCode) {
    left.text = area.name
    right.text = area.dialCode
  }
  
  func prepareForReuse() {
    left.text = nil
    right.text = nil
  }
  
  private func _buildLabel(color: UIColor) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Russell.UI.theme.font.withSize(17)
    return label
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    
    guard newSuperview != nil, left.superview == nil else { return }
    _setup()
  }
  
  private func _setup() {
    addSubview(left)
    addSubview(right)
    right.setContentHuggingPriority(.defaultLow + 2, for: .horizontal)
    right.setContentCompressionResistancePriority(.defaultHigh + 2, for: .horizontal)
    
    NSLayoutConstraint.activate([
      left.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
      left.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
      
      trailingAnchor.constraint(equalTo: right.trailingAnchor, constant: 30),
      right.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
      right.leadingAnchor.constraint(greaterThanOrEqualTo: left.trailingAnchor, constant: 15)
      ])
  }
}

// MARK: - Transitioning

extension AreaCodePickerViewController: UIViewControllerTransitioningDelegate {
  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    
    if presented == self {
      let presentationController = DimmingPresentationController(presentedViewController: presented, presenting: presenting)
      presentationController.backgroundColor = .clear
      presentationController.canTapToDismiss = true
      presentationController.dismissCompletion = { [weak delegate = self.delegate] in
        delegate?.areaCodePickerDismissed()
      }
      return presentationController
    }
    
    return nil
  }
  
}

extension AreaCodePickerViewController: DimmingPresentationControllerPresentedViewController {
  func frameOfPresentedView(in containerView: UIView) -> CGRect {
    let preferedHeight: CGFloat = view.subviews.reduce(0) { $0 + $1.intrinsicContentSize.height }
    return CGRect(x: 0, y: containerView.frame.height - preferedHeight, width: containerView.frame.width, height: preferedHeight)
  }
}
