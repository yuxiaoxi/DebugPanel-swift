//
//  MultipeerConnectivityConnectionManager.swift
//  LingoLog
//
//  Created by Roc Zhang on 2018/9/6.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
import Foundation
import MultipeerConnectivity

class MultipeerConnectivityConnectionManager: NSObject {
  
  struct Constants {
    // 1–15 characters long and valid characters include ASCII lowercase letters, numbers, and the hyphen, containing at least one letter and no adjacent hyphens
    // Otherwise app will crash when init advertiser using this
    static let serviceTypeIdentifier = "airlogs-mc"
    
    // DisplayName
    #if os(iOS)
      #if arch(i386) || arch(x86_64)
      static let displayName = "Simulator - \(UIDevice.current.name)"
      #else
      static let displayName = "\(UIDevice.current.localizedModel) - \(UIDevice.current.name)"
      #endif
    #else
    static let displayName = Host.current().localizedName ?? ""
    #endif
    
    // DeviceModel
    #if os(iOS)
    static let deviceModel = UIDevice.current.localizedModel
    #else
    static let deviceModel: String = {
      let service: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
      let cfstr = "model" as CFString
      var finalModelString: String?
      
      if let model = IORegistryEntryCreateCFProperty(service, cfstr, kCFAllocatorDefault, 0).takeUnretainedValue() as? NSData {
        if let nsstr = NSString(data: model as Data, encoding: String.Encoding.utf8.rawValue) {
          finalModelString = nsstr as String
        }
      }
      
      return finalModelString ?? "Unknow Model"
    }()
    #endif
    
    // DeviceSystemVersion
    #if os(iOS)
    static let deviceSystemVersion = UIDevice.current.systemVersion
    #else
    static let deviceSystemVersion = "\(NSAppKitVersion.current.rawValue)"
    #endif
    
    // DeviceSystem
    #if os(iOS)
    static let deviceSystem = "iOS"
    #else
    static let deviceSystem = "macOS"
    #endif
    
    // DeviceName
    #if os(iOS)
    static let deviceName = UIDevice.current.name
    #else
    static let deviceName = Host.current().localizedName ?? ""
    #endif
  }
  
  enum Event: String {
    case log
    case deviceName
    case deviceModel
    case deviceSystem
    case deviceSystemVersion
    case ping
    case pong
  }
  
  // MARK: Data Elements
  
  private var session: MCSession
  
  private let peer: MCPeerID
  
  private var advertiser: MCNearbyServiceAdvertiser
  
  private var connectedSessions: Set<MCSession> = []
  
  private var connectedPeerIDs: Set<MCPeerID> = []
  
  // MARK: Life-Cycle Methods
  
  override init() {
    peer = MCPeerID(displayName: Constants.displayName)
    session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .optional)
    advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: Constants.serviceTypeIdentifier)
    
    super.init()
    
    session.delegate = self
    advertiser.delegate = self
  }
  
  // MARK: Private Methods
  
  private func sendDeviceInfo() {
    send(content: Constants.deviceModel, eventType: .deviceModel)
    send(content: Constants.deviceSystemVersion, eventType: .deviceSystemVersion)
    send(content: Constants.deviceName, eventType: .deviceName)
    send(content: Constants.deviceSystem, eventType: .deviceSystem)
  }
  
  // MARK: Internal Methods
  
  func setReadyForConnect() {
    airlog("[AirLogs] Start advertising peer")
    advertiser.startAdvertisingPeer()
  }
  
  func disconnectAllConnection() {
    airlog("[AirLogs] Disconnect all connection peers")
    advertiser.stopAdvertisingPeer()
    session.disconnect()
    connectedSessions.forEach({ $0.disconnect() })
    connectedSessions.removeAll()
    connectedPeerIDs.removeAll()
  }
  
  func send(content: String, eventType: Event, specificPeerID: MCPeerID? = nil) {
    guard !connectedSessions.isEmpty else {
      return
    }
    
    let dictionary: [String: String] = ["event": eventType.rawValue,
                                        "content": content]
    let data = NSKeyedArchiver.archivedData(withRootObject: dictionary)
    
    do {
      if let peerID = specificPeerID {
        try session.send(data, toPeers: [peerID], with: .reliable)
      } else {
        try session.send(data, toPeers: connectedPeerIDs.map({ $0 }), with: .reliable)
      }
    } catch {
      airlog("[AirLogs] MultipeerConnectivityConnectionManager send data failed: \(error)")
    }
  }
  
}

// MARK: - MCSessionDelegate Methods

extension MultipeerConnectivityConnectionManager: MCSessionDelegate {
  
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      airlog("[AirLogs] MultipeerConnectivityConnectionManager state did changed: \(peerID), connected")
      
      if !connectedSessions.contains(session) {
        connectedSessions.insert(session)
      }
      
      if !connectedPeerIDs.contains(peerID) {
        connectedPeerIDs.insert(peerID)
      }
      
      sendDeviceInfo()
      
    case .notConnected:
      airlog("[AirLogs] MultipeerConnectivityConnectionManager state did changed: \(peerID), not connected")
      
      if connectedSessions.contains(session) {
        connectedSessions.remove(session)
      }
      
      if connectedPeerIDs.contains(peerID) {
        connectedPeerIDs.remove(peerID)
      }
      
      self.session.cancelConnectPeer(peerID)
      
    case .connecting:
      airlog("[AirLogs] MultipeerConnectivityConnectionManager state did changed: \(peerID), connecting")
    
    default:
      airlog("[AirLogs] MultipeerConnectivityConnectionManager state did changed: unknown")
    }
  }
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let dictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: String] else {
      return
    }
    
    guard let eventString = dictionary["event"], let event = Event(rawValue: eventString) else {
      return
    }
    
    switch event {
    case .ping:
      if let pingID = dictionary["content"] {
        send(content: pingID, eventType: .pong, specificPeerID: peerID)
      }
      
    default:
      break
    }
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    
  }
  
}

// MARK: - MCNearbyServiceAdvertiserDelegate Methods

extension MultipeerConnectivityConnectionManager: MCNearbyServiceAdvertiserDelegate {
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    airlog("[AirLogs] MultipeerConnectivityConnectionManager start advertising error: \(error)")
  }
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    airlog("[AirLogs] MultipeerConnectivityConnectionManager did receive invitation from: \(peerID)")
    invitationHandler(true, session)
  }
  
}

// MARK: - Helper

func airlog(_ message: String) {
  if ProcessInfo.processInfo.environment["OS_ACTIVITY_MODE"] != "disable" {
    print(message)
  }
}
