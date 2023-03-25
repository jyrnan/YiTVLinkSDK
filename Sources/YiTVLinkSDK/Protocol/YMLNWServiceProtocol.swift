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
  
  var deviceManager: DeviceManager {get set}
    
//    /// 用来查找设备的udpClient
//    var searchUdpClient: YMLNWConnection! { get set }
//    /// 用来查找设备的udpListener
//    var udpListener: YMLNWListener! { get set }
//    
    /// 监听设备，一般是应用调用者，提供各种回调
    var listener: YMLListener? { get set }
    
//    /// 搜索到当前局域网内可以连接的设备信息
//    var discoveredDevice: [DiscoveryInfo] { get set }
//    
//    /// 当前连接的设备
//    var hasConnectedToDevice: DeviceInfo? { get set }
}
