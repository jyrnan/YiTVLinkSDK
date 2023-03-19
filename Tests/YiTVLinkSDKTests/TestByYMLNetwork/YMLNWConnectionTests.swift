//
//  YMLNWConnectionTests.swift
//
//
//  Created by jyrnan on 2023/3/18.
//

import XCTest
@testable import YiTVLinkSDK
import Network

final class YMLNWConnectionTests: XCTestCase{
  var sut: YMLNWConnection!
  var delegate: YMLNWConnectionDelegate!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    delegate = MockDelegate()
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try super.tearDownWithError()
    delegate = nil
    sut = nil
  }
  
  func testInitUDPConnectionActively() {
    let port:UInt16 = 7788
    let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("127.0.0.1"), port: NWEndpoint.Port(rawValue: port)!)
    
    let sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .udp)
  }
  
  func testInitTCPConnectionActively() {
    let port:UInt16 = 7788
    let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("127.0.0.1"), port: NWEndpoint.Port(rawValue: port)!)
    
    let sut = YMLNWConnection(endpoint: endpoint, delegate: delegate)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .tcp)
  }
  
  func testConnectionNameChangeWhenReady() {
    let port:UInt16 = 7788
    let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("127.0.0.1"), port: NWEndpoint.Port(rawValue: port)!)
    
    
    let name = "127.0.0.1:7788"
    guard let delegate = delegate as? MockDelegate else {return XCTFail()}
    let connectionReadyExpectation = XCTestExpectation(description: "发送设备查找请求")
    let callback = {
      XCTAssertTrue( delegate.isConnectionReady )
      XCTAssertEqual(self.sut.name, name)
      connectionReadyExpectation.fulfill()
    }
    delegate.connectionReadyCallback = callback
    
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
    XCTAssertNotNil(sut)
    
    wait(for: [connectionReadyExpectation], timeout: 1)
  }
}

class MockDelegate: YMLNWConnectionDelegate {
  var isConnectionReady = false
  var connectionReadyCallback: (() -> Void)?
  func connectionReady(connection: YiTVLinkSDK.YMLNWConnection) {
    guard let callback = connectionReadyCallback else {return}
    isConnectionReady = true
    callback()
  }
  
  func connectionFailed(connection: YiTVLinkSDK.YMLNWConnection) {
    
  }
  
  func receivedMessage(content: Data?, connection: YiTVLinkSDK.YMLNWConnection) {
    
  }
  
  func displayAdvertiseError(_ error: NWError) {
    
  }
  
  func connectionError(connection: YiTVLinkSDK.YMLNWConnection, error: NWError) {
    
  }
  
  
}
