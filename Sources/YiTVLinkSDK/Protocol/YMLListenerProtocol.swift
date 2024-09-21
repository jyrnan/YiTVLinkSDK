//
//  YMLListener Protocol.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/11/15.
//

import Foundation

@objc public protocol YMLListener {
    func deliver(data: Data)
    func notified(with message: String)
    func deliver(devices: [DeviceInfo])
    func notified(error: Error)
}

enum YMLNotify: String {

    case TCPCONNECTED, TCPDISCONNECTED
    case UDPCONNECTED, UDPDISCONNECTED
    
    case FILE_SERVER_STARTED, FILE_SERVER_STOPPED
}
