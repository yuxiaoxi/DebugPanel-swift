//
//  Localization.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/24.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

public extension Russell {
  struct LocalizedStringTable {
    public let bundle: Bundle
    public let table: String
    
    public init(bundle: Bundle, table: String) {
      self.bundle = bundle
      self.table = table
    }
    
    func string(for key: String) -> String {
      let injected = NSLocalizedString(key, tableName: table, bundle: bundle, value: "Russell-unknown", comment: "")
      if injected == "Russell-unknown" {
        return NSLocalizedString(key, tableName: "Russell", bundle: Bundle(for: Russell.self), value: "Russell-unknown", comment: "")
      } else {
        return injected
      }
    }
  }
  
  static var localizedStringTable: LocalizedStringTable = .init(bundle: Bundle(for: Russell.self), table: "Russell")
  static var userInterfaceLocalizedStringTable: LocalizedStringTable = .init(bundle: Bundle(for: Russell.self), table: "RussellUI")
  
  internal static let _defaultLocalizedStringTable = LocalizedStringTable(bundle: Bundle(for: Russell.self), table: "Russell")
}

internal var Localization: Russell.LocalizedStringTable { return Russell.localizedStringTable }

// MARK: - Localized Error

public protocol RussellLocalizedError: LocalizedError, CaseIterable {
  static var category: String { get }
  var key: String { get }
}

public extension RussellLocalizedError {
  
  static var category: String { return String(describing: Self.self) }
  
  var errorDescription: String? {
    return Localization.string(for: "RussellError-\(Self.category)-\(key)")
  }
}

public extension RussellLocalizedError where Self: RawRepresentable, Self.RawValue == String {
  
  var key: String {
    return rawValue
  }
}
