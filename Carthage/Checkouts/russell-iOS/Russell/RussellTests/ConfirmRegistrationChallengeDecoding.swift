//
//  ConfirmRegistrationChallengeDecoding.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2019/6/21.
//  Copyright © 2019 LLS. All rights reserved.
//

import Quick
import Nimble
@testable import Russell

final class ConfirmRegistrationChalldengeDecodingSpec: QuickSpec {
  
  override func spec() {
    
    describe("decode confirm registration challenge response") {
      var response: ConfirmToRegisterChallenge?
      afterEach {
        response = nil
      }
      
      context("with extra params") {
        
        beforeEach {
          response = JSONFile.confirmRegistrationChallengeExtraParam.load()
        }
        
        it("should success") {
          expect(response).toNot(beNil())
        }
        
        it("should contain extra params") {
          expect(response?.challengeParams).toNot(beNil())
        }
        
        it("should contain extra param 'nick'") {
          expect(response?.challengeParams?["nick"]) == "x"
        }
        
        it("should not contain non string extra param 'unknown'") {
          expect(response?.challengeParams?["unknown"]).to(beNil())
        }
      }
      
      context("without extra params") {
        var response: ConfirmToRegisterChallenge?
        beforeEach {
          response = JSONFile.confirmRegistrationChallengeNoExtraParam.load()
        }
        
        it("should success") {
          expect(response).toNot(beNil())
        }
        
        it("should not contain extra params") {
          expect(response?.challengeParams).to(beNil())
        }
      }
    }
  }
}
