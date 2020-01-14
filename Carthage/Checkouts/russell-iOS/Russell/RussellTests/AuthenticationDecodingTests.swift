//
//  AuthenticationDecodingTests.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2019/2/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

private let expectedAvatar = URL(string: "https://google.com")
private let expectedUserID: UInt64 = 12345
private let referenceDate = Date(timeIntervalSince1970: 1550823363)

final class AuthenticationDecodingSpec: QuickSpec {
  
  override func spec() {
    
    describe("decoding authentication") {
      
      context("normal json") {
        let data = AuthenticationJSON.authentication1.loadData()!
        var auth: Authentication?
        beforeEach {
          auth = try? JSONDecoder().decode(Authentication.self, from: data)
        }
        
        it("should decode successfully") {
          expect(auth).toNot(beNil())
        }
        
        it("should decode access token") {
          expect(auth?.result.accessToken) == "accessToken"
        }
        
        it("should decode expiringDate") {
          expect(auth?.result.expiringDate) == referenceDate
        }
        
        it("should decode refreshToken") {
          expect(auth?.result.refreshToken) == "refreshToken"
        }
        
        it("should decode neoID") {
          expect(auth?.result.neoID) == "neoID"
        }
        
        it("should decode userID") {
          expect(auth?.result.userID) == expectedUserID
        }
        
        it("should decode avatar") {
          expect(auth?.result.avatar) == expectedAvatar
        }
        
        it("should decode isNewRegister") {
          expect(auth?.result.isNewRegister) == true
        }
      }
      
      context("short json") {
        let data = AuthenticationJSON.authentication2.loadData()!
        var auth: Authentication?
        beforeEach {
          auth = try? JSONDecoder().decode(Authentication.self, from: data)
        }
        
        it("should decode successfully") {
          expect(auth).toNot(beNil())
        }
        
        it("should decode access token") {
          expect(auth?.result.accessToken) == "accessToken"
        }
        
        it("should decode expiringDate") {
          expect(auth?.result.expiringDate) == referenceDate
        }
        
        it("should decode refreshToken") {
          expect(auth?.result.refreshToken) == "refreshToken"
        }
        
        it("should not decode neoID") {
          expect(auth?.result.neoID).to(beNil())
        }
        
        it("should decode userID") {
          expect(auth?.result.userID) == expectedUserID
        }
        
        it("should not decode avatar") {
          expect(auth?.result.avatar).to(beNil())
        }
        
        it("should decode isNewRegister") {
          expect(auth?.result.isNewRegister) == true
        }
      }
      
      context("string number json") {
        let data = AuthenticationJSON.authentication3.loadData()!
        var auth: Authentication?
        beforeEach {
          auth = try? JSONDecoder().decode(Authentication.self, from: data)
        }
        
        it("should decode successfully") {
          expect(auth).toNot(beNil())
        }
        
        it("should decode access token") {
          expect(auth?.result.accessToken) == "accessToken"
        }
        
        it("should decode expiringDate") {
          expect(auth?.result.expiringDate) == referenceDate
        }
        
        it("should decode refreshToken") {
          expect(auth?.result.refreshToken) == "refreshToken"
        }
        
        it("should decode neoID") {
          expect(auth?.result.neoID) == "neoID"
        }
        
        it("should decode userID") {
          expect(auth?.result.userID) == expectedUserID
        }
        
        it("should decode avatar") {
          expect(auth?.result.avatar) == expectedAvatar
        }
        
        it("should decode isNewRegister") {
          expect(auth?.result.isNewRegister) == false
        }
      }
      
      context("invalid date string json") {
        
        let data = AuthenticationJSON.authentication4.loadData()!
        
        it("should throw error") {
          expect(expression: { try JSONDecoder().decode(Authentication.self, from: data) }).to(throwError())
        }
      }
      
      context("invalid userID string json") {
        let data = AuthenticationJSON.authentication5.loadData()!
        
        it("should throw error") {
          expect(expression: { try JSONDecoder().decode(Authentication.self, from: data) }).to(throwError())
        }
      }
      
      context("empty avatar URL string") {
        let data = AuthenticationJSON.authentication6.loadData()!
        
        it("should not throw error") {
          expect(expression: { try JSONDecoder().decode(Authentication.self, from: data) }).toNot(throwError())
        }
        
        it("avatar URL should be nil") {
          let auth = try? JSONDecoder().decode(Authentication.self, from: data)
          expect(auth?.result.avatar).to(beNil())
        }
      }
    }
  }
}
