//
//  YMLNWServiceNewTests.swift
//
//
//  Created by jyrnan on 2023/3/18.
//

import XCTest
@testable import YiTVLinkSDK

final class YMLNWServiceUniTests: XCTestCase {
  var sut: YMLNetwork!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    try super.setUpWithError()
    sut = YMLNetwork()
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try super.tearDownWithError()
    sut = nil
  }
  
  func testSendTcpDataByMockServer() {
    let expectation = XCTestExpectation(description: "测试TCP发送数据")
    let didReceiveTcpData = { expectation.fulfill() }
    
    let receiveMockServer = ReceiveTestMockServer(port: YMLNetwork.DEV_DISCOVERY_UDP_PORT, peerType: .udp)
    receiveMockServer.callback = didReceiveTcpData

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.sut.searchDeviceInfo(searchListener: MockListener())
    }
        
    wait(for: [expectation], timeout: 1)
  }
}
