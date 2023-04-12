//
//  YMLNetwork.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/15.
//

import Foundation

public class YMLNetwork: NSObject, YMLNetworkProtocol {
  // MARK: - Types
    
  struct Status {
    private(set) var value: String
    init(_ value: String) {
      self.value = value
    }

    static let TCPConnected = Status("TCPCONNECTED")
    static let TCPDisconnected = Status("TCPDISCONNECTED")
    static let UDPConnected = Status("UDPCONNECTED")
    static let UDPDisconnected = Status("UDPDISCONNECTED")
  }

  // 兼容9.0协议端口通过广播进行设备发现的UDP接收端口
  static let DEV_DISCOVERY_UDP_PORT: UInt16 = 8000
  static let DEV_TCP_PORT: UInt16 = 8001
  static let DEV_DISCOVERY_UDP_LISTEN_PORT: UInt16 = 8009

  // MARK: - Properties

  // 模拟数据实例
//  @objc public static let mock = YMLNetwork(service: YMLNWServiceMock())
  @objc public static let shared = YMLNetwork(service: YMLNWService())
    
  private(set) var service: YMLNWServiceProtocol// = YMLNWService()
  
  lazy private(set) var fileServer = FileServer(port: 8089)
  
  public var isServerRunning: Bool { fileServer.isServerRunning}
  

  // MARK: - Initializers

  private override init() {
    self.service = YMLNWService()
  }
  
  private init(service: YMLNWServiceProtocol) {
    self.service = service
  }
  
  
    
  // MARK: - APIs
  
  @objc public func reset() {
    self.service = YMLNWService()
  }

  @objc public func initSDK(key: String) {
    service.initSDK(key: key)
  }
    
  @objc public func searchDeviceInfo(searchListener: YMLListener) {
    service.searchDeviceInfo(searchListener: searchListener)
  }
    
  @objc public func createTcpChannel(info: DeviceInfo) -> Bool {
    return service.createTcpChannel(info: info)
  }
    
  @objc public func sendTcpData(data: Data) {
    service.sendTcpData(data: data)
  }
    
  @objc public func receiveTcpData(TCPListener: YMLListener) {
    service.receiveTcpData(TCPListener: TCPListener)
  }
    
  @objc public func closeTcpChannel() {
    service.closeTcpChannel()
  }
    
  @objc public func createUdpChannel(info: DeviceInfo) -> Bool {
    return service.createUdpChannel(info: info)
  }
    
  @objc public func sendGeneralCommand(command: RemoteControl) -> Bool {
    return service.sendGeneralCommand(command: command)
  }
    
  @objc public func modifyDeviceName(name: String) {
    service.modifyDeviceName(name: name)
  }
  
  //TODO: - 考虑是不是带入Listener来实现监听？
  @objc public func shareFile(pickedURL: URL) -> String? {
    return fileServer.prepareFileForShareNoCopy(pickedURL: pickedURL)
  }
  
  @objc public func startFileSharing() {
    return fileServer.start()
  }
}
