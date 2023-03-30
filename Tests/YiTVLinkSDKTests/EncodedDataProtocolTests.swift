//
//  EncodedDataProtocolTests.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2023/3/17.
//

import XCTest
@testable import YiTVLinkSDK

final class EncodedDataProtocolTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
  
  //MARK: - 测试网络协议数据转换
  func testMakeEncodedData() {
    struct A: EncodedDatableProtocol {
      var cmd: UInt16 = 0x0005
      var ap: UInt32 = 0x01000001
      var uint8: UInt8 = 0x11
      var name: String = "hello"
    }
    
    let encodedData = [UInt8]( A().encodedData )
    let shouldData:[UInt8] = [0, 10, 0, 05, 1, 0, 0, 1, 17, 104, 101, 108, 108, 111]
    
    XCTAssertEqual(encodedData, shouldData)
  }
  
  func testMakeEncodedDataWithEnumProperty() {
    
    struct A: EncodedDatableProtocol {
      enum MouseEvent: UInt8, OneByteRawValue {
        case move               = 0x01
        case leftButtonPress    = 0x03
        case leftButtonRelease  = 0x04
      }
      enum Platform: UInt16, RawRepresentable, TwoBytesRawValue {
        case mStar  = 0x0811;
        case mLogic = 0x0211
      }
      
      enum PlayState:UInt32, RawRepresentable, FourBytesRawValue {
        case error  = 0x00000000
        case play   = 0x00000001
        case stop   = 0x00000002
        case pause  = 0x00000003
        case seek   = 0x00000004
      }
      var packetCmd: UInt16 = 0x0070
      var motion: MouseEvent = .leftButtonPress
      var count: UInt16 = 5
      var ap: UInt32 = 0x11000001
      var name: String = "hello"
      var playState: PlayState = .stop
      var type: Platform = .mLogic
      var json: String = "{com: 34}"
    }
    
    let encodedData = [UInt8]( A().encodedData )
    let shouldData:[UInt8] = [0, 27, 0, 112, 3, 0, 5, 17, 0, 0, 1, 104, 101, 108, 108, 111, 0, 0, 0, 2, 2, 17, 123, 99, 111, 109, 58, 32, 51, 52, 125]
    
    XCTAssertEqual(encodedData, shouldData)
  }
  
  func testDeviceDiscoverPacketEncodedData() {
    let deviceDiscoverPacket = DeviceDiscoveryPacket(dev_name: "My iPhone")
    let encodedData = [UInt8](deviceDiscoverPacket.encodedData)
    
    let shouldData:[UInt8] = [0, 17, 0, 112, 0, 0, 0, 0, 0, 8, 1, 1, 77, 121, 32, 105, 80, 104, 111, 110, 101]
    
    XCTAssertEqual(encodedData, shouldData)
  }
  
  func testLocalIPEncodedDataWithIPv4() {
    let sut: LocalIP = LocalIP(ip: "0.0.0.0")
    let encodedData = [UInt8](sut.encodedData)
    
    let shouldData:[UInt8] = [UInt8](repeating: 0, count: 25) + [48, 46, 48, 46, 48, 46, 48]
    
    XCTAssertEqual(encodedData, shouldData)
  }
  
  func testPlayMediaFilePacketEncodedData() {
    let sut: PlayMediaFilePacket = PlayMediaFilePacket(file_size: 0, have_next_flag: .no, local_ip: "0.0.0.0", file_name: "aaaa&MP")
    let encodedData = [UInt8](sut.encodedData)
    
    let ipData:[UInt8] = [UInt8](repeating: 0, count: 25) + [48, 46, 48, 46, 48, 46, 48]
    let fileNameData:[UInt8] = [97, 97, 97, 97, 38, 77, 80]
    let shouldData:[UInt8] = [0, 47, 32, 1] + [0, 0, 0, 0, 0, 0, 0, 0] + ipData + fileNameData

    XCTAssertEqual(encodedData, shouldData)
  }

}
