//
//  DeviceInfo.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/11/15.
//

import Foundation

public class DeviceInfo: NSObject, Codable {
    override public var description: String {
        return super.description + "\n"  + "设备信息：\n名称:\(devName)\n平台:\(platform)\n地址:\(localIp)\n版本:\(sdkVersion)"
    }

    @objc public var devAttr: Int
    @objc public var devName: String
    @objc public var platform: String
    @objc public var localIp: String
    @objc public var sdkVersion: String

    @objc public init(devAttr: Int,
                      name: String,
                      platform: String,
                      ip: String,
                      sdkVersion: String)
    {
        self.devAttr = devAttr
        self.devName = name
        self.platform = platform
        self.localIp = ip
        self.sdkVersion = sdkVersion
    }

    override public init() {
        self.devAttr = 0
        self.devName = "DeviceName"
        self.platform = "21"
        self.localIp = "127.0.0.1"
        self.sdkVersion = "Unknown"
    }
    
    static var localMockServer: DeviceInfo {
      let device: DeviceInfo = .init()
        device.devName = "localMockServer"
        return device
    }
    
    static public var sample: DeviceInfo {
        let names = ["HelloTV", "KonkaTV","MangoTV", "811TV"]
        func rNumber(_ limit: UInt32) -> Int{return Int(arc4random_uniform(limit))}
        return .init(devAttr: rNumber(10),
                     name: names[rNumber(3)],
                     platform: "21",
                     ip: "192.168.1." + String(rNumber(255)),
                     sdkVersion: "devSmaple")
    }
}

extension DeviceInfo: Identifiable {}

extension DeviceInfo {
  var isOldVersion:Bool {
    guard !sdkVersion.isEmpty else {return false}
    
    guard sdkVersion.hasPrefix("V"), let versionCharacter = sdkVersion.prefix(2).last, let versionNumber = Int(String(versionCharacter)) else {return false}
    
    return (1...8).contains(versionNumber)
  }
}
