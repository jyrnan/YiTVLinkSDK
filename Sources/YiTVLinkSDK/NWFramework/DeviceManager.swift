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
    // MARK: - Properties For network

    /// 发送设备搜索广播信息的UPD连接
    var searchUDPConnection: YMLNWConnection?
    /// 接受设备搜索广播信息的UPD监听
    var searchUDPListener: YMLNWListener?
    /// 接受设备搜索组播信息的监听
    var groupConnection: NWConnectionGroup!
  
    /// 用来随机生成设备名称，可作为收到发现设备信息的排除依据
    let randomDeviceName: String = UIDevice.current.name // String(UUID().uuidString.prefix(8))
  
    var discoveredDevice: [DiscoveryInfo] = []
    var hasConnectedToDevice: DeviceInfo?
  
    /// 监听设备，一般是应用调用者，提供各种回调
    weak var appListener: YMLListener?
  
    /// 设置是否需要在
    private var isNeededSearchDeviceWhenReady: Bool = false
  
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
        guard searchUDPConnection == nil else { return }
    
        let host = NWEndpoint.Host("255.255.255.255")
        let port = NWEndpoint.Port(rawValue: YMLNetwork.DEV_DISCOVERY_UDP_PORT)!
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        
        let connection = YMLNWConnection(endpoint: endpoint, delegate: self, type: .broadcast)
      
        searchUDPConnection = connection
    }
    
    private func setupSearchUDPListener() {
        guard searchUDPConnection == nil else { return }
    
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
        guard isNeededSearchDeviceWhenReady else { return }
    
        isNeededSearchDeviceWhenReady = false
        searchDevice()
    }
  
    ///
    func searchDevice() {
        print("Start search device...")
    
        /// 先检测SearchUDPConnection是否启动，如果没有启动则先启动
        /// 然后在connection ready的时候调用searchDevice
        guard searchUDPConnection?.connection?.state == .ready else {
            /// 设置重新搜索设备的标志位并重新设置SearchUDPConnection
            isNeededSearchDeviceWhenReady = true
            return setupSearchUDPConnection()
        }
    
        guard let listener = searchUDPListener?.listener as? NWListener, listener.state == .ready else {
            /// 设置重新搜索设备的标志位并重新设置SearchUDPListener
            isNeededSearchDeviceWhenReady = true
            return setupSearchUDPListener()
        }
        
        /// 清理原有发现设备，该操作因为交由DeviceInfoManagerActor完成，所以需要异步
        Task { await clearDiscoveredDevice() }
    
        var deviceDiscoveryPacket = DeviceDiscoveryPacket()
        deviceDiscoveryPacket.dev_name = randomDeviceName
        let deviceDiscoveryData = deviceDiscoveryPacket.encodedData
    
        searchUDPConnection?.send(content: deviceDiscoveryData)
        groupConnection.send(content: deviceDiscoveryData, completion: { _ in })
    }
  
    /// 处理发送设备搜寻广播后收到的UDP数据
    /// - Parameters:
    ///   - data: 收到的UDP数据（默认加密）
    func searchDeviceDataHandler(data: Data, endpoint: String?) {
        if let discoveredInfo = parseSearchResultData(data: data, endpoint: endpoint) {
            /// 发现设备，该操作因为交由DeviceInfoManagerActor完成，所以需要异步
            Task {await receiveOneDevice(info: discoveredInfo)}
        }
    }
    
    /// 根据收到的数据提取设备发现信息
    /// - Parameters:
    ///   - data: 收到的数据
    ///   - endpoint: 发送数据的终端网络地址信息
    /// - Returns: 返回可能的发现设备信息
    private func parseSearchResultData(data: Data, endpoint: String?) -> DiscoveryInfo? {
        guard data.count > 12 else { return nil }
    
        let ip = String(endpoint?.split(separator: ":").first ?? "Unknown")
        
        let soft_version = UInt8(data[9])
        switch soft_version {
        case 1 ... 8:
            // 旧版处理
            let (dev_name, dev_mac) = getNameAndMac(data: data[12...])
            let deviceInfo = DeviceInfo(devAttr: 0, name: dev_name, platform: "0", ip: ip, sdkVersion: "\(soft_version)")
            deviceInfo.macAddress = dev_mac
            
            let discoveryInfo = DiscoveryInfo(device: deviceInfo, TcpPort: 8001, UdpPort: 8000)
            return discoveryInfo
      
        case 9:
            // 新版本处理方式
            let dev_info = data[12...]
            guard let tvDevice = try? JSONDecoder().decode(TvDevice.self, from: dev_info) else { return nil }
            
            let deviceInfo = DeviceInfo(devAttr: 0,
                                        name: tvDevice.device.devName,
                                        platform: tvDevice.device.platform,
                                        ip: ip,
                                        sdkVersion: "\(soft_version)")
            
            deviceInfo.serialNumber = tvDevice.encodeData.serialNumber
            deviceInfo.macAddress = tvDevice.encodeData.macAddress
            
            /// 对deviceInfo内新增端口号写值
            deviceInfo.udpPort = tvDevice.encodeData.udpPort
            deviceInfo.tcpPort = tvDevice.encodeData.tcpPort
            
            let discoveryInfo = DiscoveryInfo(device: deviceInfo,
                                              TcpPort: tvDevice.encodeData.tcpPort,
                                              UdpPort: tvDevice.encodeData.udpPort)
            return discoveryInfo
    
        default:
            break
        }
        return nil
        
        func getNameAndMac(data: Data) -> (String, String) {
            guard let nameAndMac = String(data: data, encoding: .utf8)?.split(separator: "&").map(String.init), nameAndMac.count == 2 else {return ("Unkonw", "Unkonw")}
            return (nameAndMac.first!, nameAndMac.last!)
        }
    }
    
    @DeviceInfoManagerActor
    private func receiveOneDevice(info: DiscoveryInfo) {

            print("--------- Technology research UDP did receive data\n \(info.device.description)\n-----------------\n")
            /// 判断是否收到是本机信息，如果是则忽略
            guard info.device.devName != self.randomDeviceName else { return }
          
        if !self.isContainsDevice(device: info.device) {
                addDiscovery(info: info)
            let devices = self.discoveredDevice.map(\.device)
                // TODO: - 如何更新发现设备列表？目前是有发现新的就将当前所有设备全部发送一次
            self.appListener?.deliver(devices: devices)
            }
    }
    
    private func isContainsDevice(device: DeviceInfo) -> Bool {
        return discoveredDevice.map(\.device).contains {
            device.localIp == $0.localIp && device.devName == $0.devName
        }
    }
  
    @DeviceInfoManagerActor
    private func addDiscovery(info: DiscoveryInfo) {
        if !isContainsDevice(device: info.device) {
            discoveredDevice.append(info)
        }
    }
    
    @DeviceInfoManagerActor
    private func clearDiscoveredDevice() {
        discoveredDevice.removeAll()
    }
  
    // MARK: - get port
  
    func getUdpPort(from device: DeviceInfo) -> UInt16? {
//        return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.udpPort
        return device.udpPort // 由于在deviceInfo内直接添加了端口号，所以直接返回该值
    }
  
    // TODO: - 对于返回端口的策略还是需要再考虑！
    func getTcpPort(from device: DeviceInfo) -> UInt16? {
//        guard !device.isOldVersion else { return YMLNetwork.DEV_TCP_PORT }
//    
//        return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.tcpPort
        return device.tcpPort // 由于在deviceInfo内直接添加了端口号，所以直接返回该值
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

@globalActor
public actor DeviceInfoManagerActor {
    public static var shared: DeviceInfoManagerActor = .init()
}
