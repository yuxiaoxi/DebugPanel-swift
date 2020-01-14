//
//  UserInfo.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/8.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

// MARK: - UserInfo Data Structs

public extension Russell {
  
  struct UserInfo: Decodable {
    
    public var user: User
    public var profile: Profile?
    
    public enum Gender: String, Decodable {
      case male = "MALE"
      case female = "FEMALE"
      case unknown = "UNKNOWN"
    }
    
    public struct User: Decodable {
      /// neo ID (id)
      public let neoID: String?
      /// 账户 ID (login)
      public let userID: UInt64
      /// 昵称
      public var nick: String?
      /// 头像
      public var avatar: URL?
      /// 性别
      public var gender: Gender?
      /// 创建时间
      public let createTime: Date
      /// 是否已删除
      public let isDelete: Bool
      /// 是否已设置密码
      public let passwordExists: Bool
      
      enum CodingKeys: String, CodingKey {
        case neoID = "id"
        case userID = "login"
        case nick
        case avatar
        case gender
        case createTime = "createdAtUsec"
        case isDeleted
        case passwordExists = "pwdExist"
      }
      
      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        neoID = try container.decodeIfPresent(String.self, forKey: .neoID)
        userID = try container.russell_decodeStringUInt64(forKey: .userID)
        nick = try container.decodeIfPresent(String.self, forKey: .nick)
        avatar = try container.russell_decodeURLIfPresent(forKey: .avatar)
        gender = (try? container.decodeIfPresent(Gender.self, forKey: .gender)) ?? .unknown
        createTime = try container.russell_decodeUSecDate(forKey: .createTime)
        isDelete = (try? container.decodeIfPresent(Bool.self, forKey: .isDeleted)) ?? false
        passwordExists = try container.decodeIfPresent(Bool.self, forKey: .passwordExists) ?? false
      }
    }
    
    public struct Profile: Decodable {
      /// 职业
      public var profession: String?
      /// 电子邮件
      public let email: String?
      /// 加密后的手机号
      public let puppetMobile: String?
      /// 部分隐藏的手机号
      public let maskedMobile: String?
      /// 手机号是否弱绑定
      public let isMobileWeakBinding: Bool?
      /// 已绑定的第三方账户
      public let oauthAccounts: [OAuthAccounts]?
      /// 生日
      public var birthDate: BirthDate?
      
      public init() {
        profession = nil
        email = nil
        puppetMobile = nil
        oauthAccounts = nil
        birthDate = nil
        maskedMobile = nil
        isMobileWeakBinding = nil
      }
    }
    
    public struct OAuthAccounts: Decodable {
      public enum Provider: Decodable, Equatable {
        case wechat
        case qq
        case weibo
        case facebook
        case google
        case unknown(String)
        
        public init(from decoder: Decoder) throws {
          let container = try decoder.singleValueContainer()
          let value = try container.decode(String.self)
          switch value {
          case "WECHAT":
            self = .wechat
          case "QQ":
            self = .qq
          case "WEIBO":
            self = .weibo
          case "FACEBOOK":
            self = .facebook
          case "GOOGLE":
            self = .google
          default:
            self = .unknown(value)
          }
        }
        
        public static func == (lhs: Provider, rhs: Provider) -> Bool {
          switch (lhs, rhs) {
          case (.wechat, .wechat), (.qq, .qq), (.weibo, .weibo), (.facebook, .facebook), (.google, .google):
            return true
          case let (.unknown(left), .unknown(right)):
            return left == right
          default:
            return false
          }
        }
      }
      
      /// 第三方账号服务方
      public let provider: Provider
      /// 第三方账号对应的 UID
      public let uid: String?
      /// 第三方账号的昵称
      public let nick: String?
      /// 第三方账号头像
      public let avatar: URL?
      
      public enum CodingKeys: String, CodingKey {
        case provider
        case uid
        case nick
        case avatar
      }
      
      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        provider = try container.decode(Provider.self, forKey: .provider)
        uid = try container.decodeIfPresent(String.self, forKey: .uid)
        nick = try container.decodeIfPresent(String.self, forKey: .nick)
        avatar = try container.russell_decodeURLIfPresent(forKey: .avatar)
      }
    }
    
    public struct BirthDate: Decodable, Equatable {
      public var year: Int
      public var month: Int
      public var day: Int
    }
  }
}

extension Russell.UserInfo {
  
  /// 与原 user info 对比生成 diff 参数
  public func diff(from original: Russell.UserInfo) -> [String: Any] {
    var diff: [String: Any] = [:]
    
    // user diff
    if user.gender != original.user.gender {
      diff["gender"] = user.gender ?? .unknown
    }
    if user.avatar != original.user.avatar {
      diff["avatar"] = user.avatar?.absoluteString ?? ""
    }
    if user.nick != original.user.nick {
      diff["nick"] = user.nick ?? ""
    }
    
    // profile diff
    if profile?.profession != original.profile?.profession {
      diff["profession"] = profile?.profession ?? ""
    }
    if let newBirth = profile?.birthDate, newBirth != original.profile?.birthDate {
      diff["birthDate"] = ["year": newBirth.year, "month": newBirth.month, "day": newBirth.day]
    }
    
    return diff
  }
}

// MARK: - APIs

public extension Russell {
  
  /// 获取当前用户信息
  func fetchUserInfo(_ completion: @escaping (Result<Russell.UserInfo, RussellError.UserInfo>) -> Void) {
    guard let token = Russell.currentAccessToken else {
      return completion(.failure(.notLoggedIn))
    }
    
    let api = fetchUserInfoAPI(token: token)
    networkService.request(
      api: api,
      extraErrorMapping: [],
      decoder: { try JSONDecoder().decode(UserInfo.self, from: $0) }) { result in
        switch result {
        case .success(let info):
          DispatchQueue.main.async {
            completion(.success(info))
          }
        case .failure(let error):
          DispatchQueue.main.async {
            completion(.failure(.other(error)))
          }
        }
    }
  }
  
  /// 更新当前用户信息
  ///
  /// - Parameters:
  ///   - original: 旧的用户信息
  ///   - updated: 新的用户信息
  func updateUserInfo(original: Russell.UserInfo, updated: Russell.UserInfo, completion: @escaping (RussellError.UserInfo?) -> Void) {
    updateUserInfo(diff: updated.diff(from: original), completion: completion)
  }
  
  /// 更新当前用户信息
  ///
  /// - Parameters:
  ///   - diff: 需要更新的参数集合。可以通过 `Russell.UserInfo.diff(from:)` 获取
  func updateUserInfo(diff: [String: Any], completion: @escaping (RussellError.UserInfo?) -> Void) {
    guard let token = Russell.currentAccessToken else {
      return completion(.notLoggedIn)
    }
    
    let api = updateUserInfoAPI(token: token, updates: diff)
    networkService.request(
      api: api,
      extraErrorMapping: [],
      decoder: { _ in return }) { result in
        switch result {
        case .success:
          DispatchQueue.main.async { completion(nil) }
        case .failure(let error):
          DispatchQueue.main.async { completion(.other(error)) }
        }
    }
  }
}

private extension Russell {
  
  @inline(__always)
  func fetchUserInfoAPI(token: String) -> API<Russell.UserInfo> {
    return API(method: .get,
               path: "/api/v2/user",
               body: nil,
               extraHeaders: headers(from: token))
  }
  
  @inline(__always)
  func updateUserInfoAPI(token: String, updates: [String: Any]) -> API<Void> {
    return API(method: .put,
               path: "/api/v2/user",
               body: updates,
               extraHeaders: headers(from: token))
  }
  
  private func headers(from token: String) -> [String: String] {
    return [
      "Authorization": "Bearer \(token)",
      "X-Device-ID": deviceID,
      "X-S-Device-ID": deviceID
    ]
  }
}
