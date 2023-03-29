//
//  YMLNWService.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/16.
//

import Foundation
import Network

@available(iOS 14.0, *)
class YMLNWService: NSObject, YMLNWServiceProtocol, YMLNWConnectionDelegate, YMLNWListenerDelegate {
  var serviceKey = "serviceKey"
    
  // MARK: - YMLNetworkProtocol

  var tcpClient: YMLNWConnection?
  var udpClient: YMLNWConnection?
  
  /// 应用提供回调
  weak var listener: YMLListener?
    
  var deviceManager = DeviceManager()
  
  // MARK: - YMLNetworkProtocol

  func initSDK(key: String) {
    serviceKey = key
  }
    
  func searchDeviceInfo(searchListener: YMLListener) {
    deviceManager.appListener = searchListener
    deviceManager.searchDevice()
  }
    
  /// 创建到指定设备的TCP连接，这个方法会真正创建TCP连接
  /// - Parameter info: 要连接的设备信息
  /// - Returns: 连接创建是否成功
  func createTcpChannel(info: DeviceInfo) -> Bool {
    let host = NWEndpoint.Host(info.localIp)
    guard let port = NWEndpoint.Port(rawValue: deviceManager.getTcpPort(from: info)!) else { return false }
    let endPoint = NWEndpoint.hostPort(host: host, port: port)
    let connection = YMLNWConnection(endpoint: endPoint, delegate: self, type: .tcp)
    tcpClient = connection

    deviceManager.hasConnectedToDevice = info
    return tcpClient != nil
  }
    
  func sendTcpData(data: Data) {
    guard let client = tcpClient else { return }
        
    client.send(content: data)
  }
    
  /// 需要最先设置此方法来设置回调YMLListener
  /// - Parameter TCPListener: 回调YMLListener
  func receiveTcpData(TCPListener: YMLListener) {
    listener = TCPListener
  }
    
  func closeTcpChannel() {
    guard let client = tcpClient else { return }
        
    client.cancel()
  }
    
  func createUdpChannel(info: DeviceInfo) -> Bool {
    let host = NWEndpoint.Host(info.localIp)
    guard let port = NWEndpoint.Port(rawValue: deviceManager.getUdpPort(from: info)!) else { return false }
    let endPoint = NWEndpoint.hostPort(host: host, port: port)
    let connection = YMLNWConnection(endpoint: endPoint, delegate: self, type: .udp)
    udpClient = connection
       
    deviceManager.hasConnectedToDevice = info
    return true
  }
    
  func sendGeneralCommand(command rc: RemoteControl) -> Bool {
    let message = MessageWrapper(value: rc)
    guard let commandData = try? JSONEncoder().encode(message) else { return false }
    guard let client = udpClient else { return false }
    client.send(content: commandData)
    return true
  }
    
  func modifyDeviceName(name: String) {}
    
  // MARK: - YMLNWListenerDelegate
    
  func ListenerReady() {}
    
  func ListenerFailed() {}
    
  // MARK: - YMLNWConnectionDelegate
    
  func connectionReady(connection: YMLNWConnection) {
    switch connection.type {
    case .tcp:
      listener?.notified(with: "TCPCONNECTED")
    case .udp:
      listener?.notified(with: "UDPCONNECTED")
    default:
      break
    }
  }
    
  func connectionFailed(connection: YMLNWConnection) {
    switch connection.type {
    case .tcp:
      listener?.notified(with: "TCPDISCONNECTED")
    case .udp:
      listener?.notified(with: "UDPDISCONNECTED")
    default:
      break
    }
  }
    
  func receivedMessage(content: Data?, connection: YMLNWConnection) {
    guard let data = content else { return }
    
    listener?.deliver(data: data)
  }
    
  func connectionError(connection: YMLNWConnection, error: NWError) {
    listener?.notified(error: error)
  }
}

