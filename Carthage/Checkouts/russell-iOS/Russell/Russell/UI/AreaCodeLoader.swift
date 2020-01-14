//
//  AreaCodeLoader.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class AreaCodeLoader {
  
  static let shared = AreaCodeLoader()
  private init() {}
  /// [dialCode: AreaCodeIndex]
  private(set) lazy var dialAreaCodeMap: [String: Int]  = {
    
    return self.areaCodes.enumerated().reduce(into: [:]) { (_ result, elem) in
      result[elem.1.dialCode] = elem.0
    }
  }()
  
  private(set) lazy var areaCodes: [AreaCode] = {
    let url = Bundle(for: AreaCodeLoader.self).url(forResource: "countryCodes", withExtension: "json")!
    //swiftlint:disable force_try
    let inputCodes = try! JSONDecoder().decode([AreaCode].self, from: Data(contentsOf: url))
    //swiftlint:enable force_try
    return inputCodes
      .map { AreaCode(name: _localizedName(for: $0), dialCode: $0.dialCode, countryCode: $0.countryCode) }
      .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
  }()
  
  @inline(__always)
  private func _localizedName(for code: AreaCode) -> String {
    guard let locale = Locale.preferredLanguages.first.map(Locale.init(identifier:)) else {
      return code.name
    }
    
    if code.countryCode == "TW" && locale.languageCode == "zh" {
      return "\(locale.localizedString(forRegionCode: code.countryCode) ?? "")（\(locale.localizedString(forRegionCode: "CN") ?? "")）"
    } else {
      return locale.localizedString(forRegionCode: code.countryCode) ?? code.name
    }
  }
}

struct AreaCode: Decodable {
  let name: String
  let dialCode: String
  let countryCode: String
  
  enum CodingKeys: String, CodingKey {
    case name
    case dialCode = "dial_code"
    case countryCode = "code"
  }
}
