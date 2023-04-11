//
//  YMLNWServiceMock.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2023/1/12.
//

import Foundation
import Network

class YMLNWServiceMock: YMLNWServiceProtocol, YMLNWConnectionDelegate, YMLNWListenerDelegate {
  var deviceManager: DeviceManager = .init()
  
  var tcpClient: YiTVLinkSDK.YMLNWConnection?
  var udpClient: YiTVLinkSDK.YMLNWConnection?
    
  var appListener: YiTVLinkSDK.YMLListener?
    
  func initSDK(key: String) {}
    
  func searchDeviceInfo(searchListener: YiTVLinkSDK.YMLListener) {
    appListener = searchListener
    let devices = [DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample]
    deviceManager.discoveredDevice = devices.map { DiscoveryInfo(device: $0, TcpPort: 0, UdpPort: 0) }
    appListener?.deliver(devices: [DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample])
  }
    
  func createTcpChannel(info: YiTVLinkSDK.DeviceInfo) -> Bool {
    appListener?.notified(with: "TCPCONNECTED")
    return true
  }
    
  func sendTcpData(data: Data) {
    appListener?.notified(with: "Data sent: \(data)")
  }
    
  func receiveTcpData(TCPListener: YiTVLinkSDK.YMLListener) {
    appListener = TCPListener
  }
    
  func closeTcpChannel() {
    tcpClient = nil
    appListener?.notified(with: "TCPDISCONNECTED")
  }
    
  func createUdpChannel(info: YiTVLinkSDK.DeviceInfo) -> Bool {
    return true
  }
    
  func sendGeneralCommand(command: RemoteControl) -> Bool {
    appListener?.notified(with: "General command sent: \(command)")
    return true
  }
    
  func modifyDeviceName(name: String) {}
    
  private func echo(data: Data) {
    appListener?.deliver(data: data)
  }
  
  func ListenerReady() {}
    
  func ListenerFailed() {}
    
  func connectionReady(connection: YMLNWConnection) {}
    
  func connectionFailed(connection: YMLNWConnection) {}
    
  func receivedMessage(content: Data?, connection: YMLNWConnection) {}
        
  func connectionError(connection: YMLNWConnection, error: NWError) {}
}
