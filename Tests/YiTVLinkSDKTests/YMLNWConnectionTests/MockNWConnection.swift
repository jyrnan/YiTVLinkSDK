//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/23.
//

import Foundation
import Network
@testable import YiTVLinkSDK

class MockNWConnection: ConnectionProtocol {
  let endpoint: NWEndpoint
  var stateUpdateHandler: ((_ state: NWConnection.State) -> Void)?
  var pathUpdateHandler: ((_ newPath: NWPath) -> Void)?
  var state: NWConnection.State = .ready
  
  var sentData: Data?
  
  var sendCompletion: NWConnection.SendCompletion?
  var receiveMessageCompletion: ((_ completeContent: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void)?
  var receiveCompletion: ((_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void)?
  
  var cancelWasCalled: Bool = false
  var startWasCalled: Bool = false
  
  init(endpoint: NWEndpoint) {
    self.endpoint = endpoint
  }

  func send(content: Data?, contentContext: NWConnection.ContentContext = .defaultMessage, isComplete: Bool = true, completion: NWConnection.SendCompletion) {
    sentData = content
    sendCompletion = completion
  }
  
  func receiveMessage(completion: @escaping (_ completeContent: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void) {
    receiveMessageCompletion = completion
  }

  func receive(minimumIncompleteLength: Int, maximumLength: Int, completion: @escaping (_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void) {
    receiveCompletion = completion
  }

  func start(queue: DispatchQueue) {
    startWasCalled = true
  }

  func cancel() {
    cancelWasCalled = true
  }
}
