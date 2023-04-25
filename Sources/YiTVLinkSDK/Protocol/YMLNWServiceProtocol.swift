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

  var deviceManager: DeviceManager { get set }

  /// 监听设备，一般是应用调用者，提供各种回调
  var appListener: YMLListener? { get set }
  
  var fileServer: FileServer {get set}
}
