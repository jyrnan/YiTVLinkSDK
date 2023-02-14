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
