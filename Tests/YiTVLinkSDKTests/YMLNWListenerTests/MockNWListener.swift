//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/23.
//

import Foundation
import Network
@testable import YiTVLinkSDK

class MockNWListener: ListenerProtocol {
  var stateUpdateHandler: ((NWListener.State) -> Void)?
  
  var newConnectionHandler: ((NWConnection) -> Void)?
  
  var port: NWEndpoint.Port?
  
  var cancelWasCalled: Bool = false
  var startWasCalled: Bool = false
  
  func start(queue: DispatchQueue) {
    startWasCalled = true
  }
  
  func cancel() {
    cancelWasCalled = true
  }
}
