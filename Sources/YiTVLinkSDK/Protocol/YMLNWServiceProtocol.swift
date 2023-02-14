//
//  YMLNWServiceProtocol.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/15.
//

import Foundation

protocol YMLNWServiceProtocol: YMLNetworkProtocol {
    /// 创建Tcp连接
    var tcpClient: YMLNWConnection? { get set }
    /// 创建Udp连接
    var udpClient: YMLNWConnection? { get set }
    
    /// 用来查找设备的udpClient
    var searchUdpClient: YMLNWConnection! { get set }
    /// 用来查找设备的udpListener
    var udpListener: YMLNWListener! { get set }
    
    /// 监听设备，一般是应用调用者，提供各种回调
    var lisener: YMLListener? { get set }
    
    /// 搜索到当前局域网内可以连接的设备信息
    var discoveredDevice: [DiscoveryInfo] { get set }
    
    /// 当前连接的设备
    var hasConnectedToDevice: DeviceInfo? { get set }
}

extension YMLNWServiceProtocol {
    func getUdpPort(from device: DeviceInfo) -> UInt16? {
        return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.udpPort
    }
    
    func getTcpPort(from device: DeviceInfo) -> UInt16? {
        return discoveredDevice.filter { $0.device.localIp == device.localIp }.first?.tcpPort
    }
    
    func makeGeneralCommandSendPack(with command: String, and data: KEYData) -> Data {
        var sampleMouseMoveData = Data(capacity: 11)
        sampleMouseMoveData.append(contentsOf: [0x00, 0x07, 0x10, 0x04])
        sampleMouseMoveData.append(contentsOf: [0x01])
        sampleMouseMoveData.append(contentsOf: [0x00, 0x01, 0x00, 0x01])
        sampleMouseMoveData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        return sampleMouseMoveData
    }
}
