//
//  BaseMockListener.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/11.
//

import XCTest
import YiTVLinkSDK

class BaseMockListener: YMLListener {
  var callback: (() -> Void)?
  
  init(callback: ( () -> Void)? = nil) {
    self.callback = callback
  }
  
  func notified(error: Error) {}
    
  func deliver(data: Data) {}
    
  func deliver(devices: [DeviceInfo]) {}
    
  func notified(with message: String) {}
}

class SearchDeviceMockListener: BaseMockListener {
  override func deliver(devices: [DeviceInfo]) {
      print(#line, #file, #function, devices)
    callback?()
  }
}

class NotifiedMessageMockListener: BaseMockListener {
  var message: String?
  override func notified(with message: String) {
    self.message = message
    callback?()
  }
}

class ReceiveDataMockListener: BaseMockListener {
  var data: Data?
  override func deliver(data: Data) {
    self.data = data
    callback?()
  }
}
