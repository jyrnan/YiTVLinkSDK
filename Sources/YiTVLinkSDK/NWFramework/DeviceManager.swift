//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/24.
//

import Foundation
import Network
import UIKit

class DeviceManager: YMLNWListenerDelegate {
  //MARK: - Properties For network
  /// 发送设备搜索广播信息的UPD连接
  var searchUDPConnection: YMLNWConnection?
  /// 接受设备搜索广播信息的UPD监听
  var searchUDPListener: YMLNWListener?
  /// 接受设备搜索组播信息的监听
  var groupConnection: NWConnectionGroup!
  
  /// 用来随机生成设备名称，可作为收到发现设备信息的排除依据
  let randomDeviceName: String = UIDevice.current.name//String(UUID().uuidString.prefix(8))
  
  
  var discoveredDevice: [DiscoveryInfo] = []
  var hasConnectedToDevice: DeviceInfo?
  
  /// 监听设备，一般是应用调用者，提供各种回调
  weak var appListener: YMLListener?
  
  
  /// 设置是否需要在
  private var isNeededSearchDeviceWhenReady:Bool = false
  
  init(listener: YMLListener? = nil) {
    
    appListener = listener
    setup()
  }
  
  // MARK: - Network client and Listener setup
  
  /// 设置全部监听或连接
  private func setup() {
    /// 这里需要先设置监听端口，否则在iOS15系统上有相当大几率启动监听端口会提示端口占用。
    setupSearchUDPListener()
    setupSearchUDPConnection()
    setupGroupConnection()
  }
  
  private func setupSearchUDPConnection() {
    guard searchUDPConnection == nil else {return}
    
    let host = NWEndpoint.Host("255.255.255.255")
    let port = NWEndpoint.Port(rawValue: YMLNetwork.DEV_DISCOVERY_UDP_PORT)!
    let endpoint = NWEndpoint.hostPort(host: host, port: port)
        
    let connection = YMLNWConnection(endpoint: endpoint, delegate: self, type: .broadcast)
      
    searchUDPConnection = connection
  }
    
  private func setupSearchUDPListener() {
    guard searchUDPConnection == nil else {return}
    
    let port: UInt16 = YMLNetwork.DEV_DISCOVERY_UDP_LISTEN_PORT
    let listener = YMLNWListener(on: port, delegate: self, type: .udp)
    searchUDPListener = listener
  }
  
  private func setupGroupConnection() {
    let multicastEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("224.0.0.251"),
                                                port: NWEndpoint.Port(rawValue: 8000)!)
     
    let groupDescription = try! NWMulticastGroup(for: [multicastEndpoint], disableUnicast: false)
    let groupConnection = NWConnectionGroup(with: groupDescription, using: .udp)
    
    groupConnection.setReceiveHandler(rejectOversizedMessages: false, handler: { message, data, _ in
      
      if let data = data {
       
        let remoteEndpoint = message.remoteEndpoint?.debugDescription
        self.searchDeviceDataHandler(data: data, endpoint: remoteEndpoint)
      }
    })

    groupConnection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        print(#line, #function, "Group is ready\n")
      default:
        print(#line, #function, "Group is down\n")
      }
    }
    
    groupConnection.start(queue: .global())
   
    self.groupConnection = groupConnection
  }
    
  // MARK: - SearchDevice Methods
  
  /// 依据标志位来进行再次搜索
  private func reSearchDeviceIfNeed() {
    guard isNeededSearchDeviceWhenReady else {return}
    
    isNeededSearchDeviceWhenReady = false
    searchDevice()
  }
  
  /// <#Description#>
  func searchDevice() {
    print("Start search device...")
    
    /// 先检测SearchUDPConnection是否启动，如果没有启动则先启动
    /// 然后在connection ready的时候调用searchDevice
    guard searchUDPConnection?.connection?.state == .ready else {
      /// 设置重新搜索设备的标志位并重新设置SearchUDPConnection
      isNeededSearchDeviceWhenReady = true
      return setupSearchUDPConnection()}
    
    guard let listener = searchUDPListener?.listener as? NWListener, listener.state == .ready else {
      /// 设置重新搜索设备的标志位并重新设置SearchUDPListener
      isNeededSearchDeviceWhenReady = true
      return setupSearchUDPListener()}
    
    clearDiscoveredDevice()
    
    var deviceDiscoveryPacket = DeviceDiscoveryPacket()
    deviceDiscoveryPacket.dev_name = randomDeviceName
    let deviceDiscoveryData = deviceDiscoveryPacket.encodedData
    
    searchUDPConnection?.send(content: deviceDiscoveryData)
    groupConnection.send(content: deviceDiscoveryData, completion: {_ in })
  }
  
  /// 处理发送设备搜寻广播后收到的UDP数据
  /// - Parameters:
  ///   - data: 收到的UDP数据（默认加密）
  func searchDeviceDataHandler(data: Data, endpoint: String?) {
    if let discoveredInfo = parseSearchResultData(data: data, endpoint: endpoint) {
      receiveOneDevice(info: discoveredInfo)
    }
  }
  
  private func parseSearchResultData(data: Data, endpoint: String?) -> DiscoveryInfo? {
    guard data.count > 12 else { return nil }
    
    let soft_version = UInt8(data[9])
    switch soft_version {
    case 1 ... 8:
      // 旧版处理
      let dev_name = String(data: data[12...], encoding: .utf8) ?? "Unknown"
      let ip = String(endpoint?.split(separator: ":").first ?? "Unknown")
      let deviceInfo = DeviceInfo(devAttr: 0, name: dev_name, platform: "0", ip: ip, sdkVersion: "\(soft_version)")
      let discoveryInfo = DiscoveryInfo(device: deviceInfo, TcpPort: 8001, UdpPort: 8000)
      return discoveryInfo
      
    case 9:
      // 新版本处理方式
      let dev_info = data[12...]
      guard let discoveredInfo = try? JSONDecoder().decode(DiscoveryInfo.self, from: dev_info) else { return nil }
      return discoveredInfo
    
    default:
      break
    }
    return nil
  }
  
  private func receiveOneDevice(info: DiscoveryInfo) {
    print("--------- Technology research UDP did receive data\n \(info.device.description)\n-----------------\n")
    
    /// 判断是否收到是本机信息，如果是则忽略
    guard info.device.devName != randomDeviceName else {return}
        
    if !isContainsDevice(device: info.device) {
      addDiscovery(info: info)
                
      let devices = discoveredDevice.map(\.device)
      // TODO: - 如何更新发现设备列表？目前是有发现新的就将当前所有设备全部发送一次
      appListener?.deliver(devices: devices)
    }
  }
    
  private func isContainsDevice(device: DeviceInfo) -> Bool {
    return discoveredDevice.map(\.device).contains {
      return device.localIp == $0.localIp && device.devName == $0.devName
    }
  }
    
  private func addDiscovery(info: DiscoveryInfo) {
    if !isContainsDevice(device: info.device) {
      discoveredDevice.append(info)
    }
  }
    
  private func clearDiscoveredDevice() {
    return discoveredDevice.removeAll()
  }
  
  // MARK: - get port
  
  func getUdpPort(from device: DeviceInfo) -> UInt16? {
    return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.udpPort
  }
  
  //TODO: - 对于返回端口的策略还是需要再考虑！
  func getTcpPort(from device: DeviceInfo) -> UInt16? {
    guard !device.isOldVersion else {return YMLNetwork.DEV_TCP_PORT}
    
    return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.tcpPort
  }
  
  // MARK: - YMLNWListenerDelegate
  
  func ListenerReady() {
    print(#line, #function, "searchUDPListener is ready\n")
    reSearchDeviceIfNeed()
  }
  
  func ListenerFailed() {
    print(#line, #function, "searchUDPListener is failed\n")
    searchUDPListener = nil
  }
  
  // MARK: - YMLNWConnectionDelegate

  func connectionReady(connection: YMLNWConnection) {
    print(#line, #function, "searchUDPConnection is ready.\n")
    /// 连接建立好时候根据情况调用调用searchDevice
    ///  但首次调用返回结果可能因为没有设置appListern无法将devece传给app
    reSearchDeviceIfNeed()
  }
  
  func connectionFailed(connection: YMLNWConnection) {
    print(#line, #function, "searchUDPConnection is failed\n")
    searchUDPConnection = nil
  }
  
  // 处理收到的设备发现数据
  func receivedMessage(content: Data?, connection: YMLNWConnection) {
    guard let data = content else { return }
    let endpoint = connection.connection?.endpoint.debugDescription
    
    searchDeviceDataHandler(data: data, endpoint: endpoint)
  }
    
  func connectionError(connection: YMLNWConnection, error: NWError) {}
}
