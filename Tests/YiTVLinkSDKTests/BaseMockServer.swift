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
  var callback: (() -> Void)?
  
  init(port: UInt16, peerType: PeerType) {
    super.init()
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
  
  func displayAdvertiseError(_ error: NWError) {}
  
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {}
  
  func ListenerReady() {}
  
  func ListenerFailed() {}
  
  // MARK: - 数据处理
  
  /// 返回查找设备的数据
//  func echoFoundDeviceData() -> Data {
//
//      let mockDevice = DeviceInfo()
//      mockDevice.devName = "mockDevice"
//
//      let mockDiscoveryInfo = DiscoveryInfo(device: mockDevice, TcpPort: tcpPort, UdpPort: udpPort)
//      mockDiscoveryInfo.cmd = 113
//
//      let mockDiscoveryInfoJson = try! JSONEncoder().encode(mockDiscoveryInfo)
//
//      return mockDiscoveryInfoJson
//  }
}

class ReceiveTestMockServer: BaseMockServer {
  override func receivedMessage(content: Data?, connection: YMLNWConnection) {
    guard let callback = callback else { return }
    callback()
  }
}
