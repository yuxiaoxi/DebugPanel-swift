//
//  AreaCodeSearchViewController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/23.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

final class AreaCodeSearchViewController: UIViewController {
  
  weak var delegate: AreaCodeSelectionDelegate?
  
  private let filter = AreaCodeFilter()
  private weak var searchBar: UISearchBar!
  private weak var tableView: UITableView!
  private let keyboardReactor = ScrollViewKeyboardReactor()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    
    searchBar = _buildSearchBar()
    tableView = _buildTableView()
    keyboardReactor.scrollView = tableView
    
    NSLayoutConstraint.activate([
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0),
      view.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 0),
      
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 0),
      view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: 0),
      view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 0)
      ])
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchBar.becomeFirstResponder()
    tableView.reloadData()
  }
  
  private func _buildSearchBar() -> UISearchBar {
    let searchBar = UISearchBar()
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.enablesReturnKeyAutomatically = true
    searchBar.showsCancelButton = true
    searchBar.delegate = self
    searchBar.tintColor = Russell.UI.theme.tintColor
    view.addSubview(searchBar)
    
    return searchBar
  }
  
  private func _buildTableView() -> UITableView {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.allowsMultipleSelection = false
    tableView.allowsSelection = true
    tableView.dataSource = filter
    tableView.delegate = self
    view.addSubview(tableView)
    
    return tableView
  }
  
  private func _complete(_ selectedDial: String?) {
    if let selectedDial = selectedDial {
      dismiss(animated: true, completion: { self.delegate?.updateSelection(selectedDial) })
    } else {
      dismiss(animated: true, completion: nil)
    }
  }
}

// MARK: - Filter

private final class AreaCodeFilter: NSObject {
  private(set) var searchResults: [AreaCode] = AreaCodeLoader.shared.areaCodes
  
  func updateSearchResult(_ keyword: String) {
    guard !keyword.isEmpty else {
      return searchResults = AreaCodeLoader.shared.areaCodes
    }
    
    searchResults = AreaCodeLoader.shared.areaCodes.filter { item in
      if item.name.lowercased().contains(keyword.lowercased()) {
        return true
      } else if item.countryCode.lowercased().contains(keyword.lowercased()) {
        return true
      } else if item.dialCode.lowercased().contains(keyword.lowercased()) {
        return true
      }
      return false
    }
  }
}

extension AreaCodeFilter: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let reuseIdentifier = "com.liulishuo.Russell.UI.AreaCodeSearchViewController.Cell"
    let cell: UITableViewCell
    if let reusable = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
      cell = reusable
    } else {
      cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    guard indexPath.row < searchResults.count else { return cell }
    
    cell.textLabel?.text = searchResults[indexPath.row].name
    cell.detailTextLabel?.text = searchResults[indexPath.row].dialCode
    return cell
  }
}

// MARK: -

extension AreaCodeSearchViewController: UISearchBarDelegate {
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    filter.updateSearchResult(searchText)
    tableView.reloadData()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    _complete(nil)
  }
  
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
}

// MARK: -

extension AreaCodeSearchViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < filter.searchResults.endIndex else { return }
    _complete(filter.searchResults[indexPath.row].dialCode)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 44
  }
}
