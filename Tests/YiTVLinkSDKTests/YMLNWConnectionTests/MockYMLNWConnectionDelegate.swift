//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/19.
//

import Foundation
import Network
@testable import YiTVLinkSDK

class MockYMLNWConnectionDelegate: YMLNWConnectionDelegate {
  var connectionReadyWasCalled = false
  var connectionFailedWasCalled = false
  var receiveMessageContent:Data?
  var displayAdvertiseError: NWError?
  var connectionError: NWError?
  
  var connectionReadyCallback: (() -> Void)?
  
  func connectionReady(connection: YiTVLinkSDK.YMLNWConnection) {
    connectionReadyWasCalled = true
    if let callback = connectionReadyCallback { callback()}
  }
  
  func connectionFailed(connection: YiTVLinkSDK.YMLNWConnection) {
    connectionFailedWasCalled = true
  }
  
  func receivedMessage(content: Data?, connection: YiTVLinkSDK.YMLNWConnection) {
    receiveMessageContent = content
  }
  
  func displayAdvertiseError(_ error: NWError) {
    displayAdvertiseError = error
  }
  
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {
    connectionError = error
  }
}
