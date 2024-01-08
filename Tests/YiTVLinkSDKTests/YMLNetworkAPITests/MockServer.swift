//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/18.
//

import Foundation
import Network
@testable import YiTVLinkSDK

class BaseMockServer: NSObject, YMLNWListenerDelegate {
  var server: YMLNWListener!
  var port: UInt16!
  var callback: (() -> Void)?
  var echo: Data?
  
  init(port: UInt16, peerType: PeerType) {
    super.init()
    self.port = port
    self.server = YMLNWListener(on: port, delegate: self, type: peerType)
    server.startListening()
  }
  
  func close() {
    server.stopListening()
  }
  
  // MARK: - Delegate methods
  
  func connectionReady(connection: YiTVLinkSDK.YMLNWConnection) {}
  
  func connectionFailed(connection: YiTVLinkSDK.YMLNWConnection) {}
  
  func receivedMessage(content: Data?, connection: YiTVLinkSDK.YMLNWConnection) {}
    
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {}
  
  func ListenerReady() {}
  
  func ListenerFailed() {}
}

class ReceiveMockServer: BaseMockServer {
  var content: Data?
  override func receivedMessage(content: Data?, connection: YMLNWConnection) {
    self.content = content
    callback?()
  }
}

class EchoMockServer: BaseMockServer {
  
  override func receivedMessage(content: Data?, connection: YMLNWConnection) {
    guard let content = content else { return }
    callback?()
    
    if let echo = echo {
      connection.send(content: echo)
    } else {
      connection.send(content: content)
    }
    
  }
}

class SearchDeviceEchoMockServer: BaseMockServer {
    lazy var client: YMLNWConnection = YMLNWConnection(endpoint: NWEndpoint.hostPort(host: "127.0.0.1", port: 8009), delegate: self, type: .udp)
    
    override func receivedMessage(content: Data?, connection: YMLNWConnection) {
      guard let content = content else { return }
      callback?()
      
        
      if let echo = echo {
        connection.send(content: echo)
          client.send(content: echo)
      } else {
        connection.send(content: content)
      }
    }
}
