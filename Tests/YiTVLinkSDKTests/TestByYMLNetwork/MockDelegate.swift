//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/19.
//

import Foundation
@testable import YiTVLinkSDK
import Network


class MockDelegate: YMLNWConnectionDelegate {
  var connectionReadyWasCalled = false
  var connectionFailed = false
  var connectionReadyCallback: (() -> Void)?
  
  func connectionReady(connection: YiTVLinkSDK.YMLNWConnection) {
    guard let callback = connectionReadyCallback else {return}
    connectionReadyWasCalled = true
    callback()
  }
  
  func connectionFailed(connection: YiTVLinkSDK.YMLNWConnection) {
    connectionFailed = true
  }
  
  func receivedMessage(content: Data?, connection: YiTVLinkSDK.YMLNWConnection) {
    
  }
  
  func displayAdvertiseError(_ error: NWError) {
    
  }
  
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {
    
  }
  
  
}
