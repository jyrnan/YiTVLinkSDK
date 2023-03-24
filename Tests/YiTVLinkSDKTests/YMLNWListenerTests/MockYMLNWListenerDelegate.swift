//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/23.
//

import Foundation
import Network
@testable import YiTVLinkSDK

class MockYMLNWListenerDelegate: YMLNWListenerDelegate {
  var ListenerReadyWasCalled = false
  var ListenerFailedWasCalled = false
  
  var connectionReadyWasCalled = false
  var connectionFailedWasCalled = false
  var receiveMessageContent:Data?
  var displayAdvertiseError: NWError?
  var connectionError: NWError?
  
  var connectionId: UUID?
  
  func ListenerReady() {
    ListenerReadyWasCalled = true
  }
  
  func ListenerFailed() {
    ListenerFailedWasCalled = true
  }
  
  func connectionReady(connection: YiTVLinkSDK.YMLNWConnection) {
    connectionReadyWasCalled = true
    connectionId = connection.id
  }
  
  func connectionFailed(connection: YiTVLinkSDK.YMLNWConnection) {
    connectionFailedWasCalled = true
    connectionId = connection.id
  }
  
  func receivedMessage(content: Data?, connection: YiTVLinkSDK.YMLNWConnection) {
    receiveMessageContent = content
    connectionId = connection.id
  }
  
  func displayAdvertiseError(_ error: NWError) {
    displayAdvertiseError = error
  }
  
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {
    connectionError = error
    connectionId = connection.id
  }
  
  
}
