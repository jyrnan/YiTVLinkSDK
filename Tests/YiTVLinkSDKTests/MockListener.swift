//
//  MockListener.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/11.
//

import YiTVLinkSDK
import XCTest

class MockListener: YMLListener {
    func notified(error: Error) {
        
    }
    
    
    public init(shouldRecieveData: Data? = nil, shouldRecieveMessage: String? = nil) {
        self.shouldRecieveData = shouldRecieveData
        self.shouldRecieveMessage = shouldRecieveMessage
    }
    
    typealias Callback = Optional<() -> Void>
    let shouldRecieveData: Data?
    let shouldRecieveMessage: String?

    var onDeliver: Callback = nil
    var onDeliverDeviceInfo: Callback = nil
    var onNotified: Callback = nil
    var onAccept: Callback = nil
//    var onRecieveTcpData: Callback = nil
    
    var expectation: XCTestExpectation? = nil
    
    var message: String = ""
    
    func deliver(data: Data) {
        if data == shouldRecieveData {
            self.onDeliver?()
        }
    }
    
    func deliver(devices: [DeviceInfo]) {
        print(#function)
        self.onDeliverDeviceInfo?()
    }
    
    func notified(with message: String) {
        if message == shouldRecieveMessage {
            self.onNotified?()
        }
    }
    
}
