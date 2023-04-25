//
//  YMLNetwork.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/15.
//

import Foundation

public class YMLNetwork: NSObject, YMLNetworkProtocol {
  // MARK: - Types

  // 兼容9.0协议端口通过广播进行设备发现的UDP接收端口
  static let DEV_DISCOVERY_UDP_PORT: UInt16 = 8000
  static let DEV_TCP_PORT: UInt16 = 8001
  static let DEV_DISCOVERY_UDP_LISTEN_PORT: UInt16 = 8009
  
  //TODO: - HTTPSERVER是否需要动态端口？
  static let DEV_HTTP_SERVER_PORT: Int = 8089

  // MARK: - Properties

  @objc public static let shared = YMLNetwork()
    
  private(set) var service = YMLNWService()
  
  /// 标识http服务是否运行
  public var isServerRunning: Bool { service.fileServer.isServerRunning}
  
  // MARK: - Initializers

  private override init() {}
    
  // MARK: - APIs
  
#if TEST
  //用来重置服务，仅在测试环境下生效
  @objc public func reset() {
    self.service = YMLNWService()
  }
  #endif

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
    return service.fileServer.prepareFileForShareNoCopy(pickedURL: pickedURL)
  }
  
  @objc public func startFileSharing() {
    return service.fileServer.start()
  }
}
