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
  var delegate: MockDelegate!
  var mockConnection: MockConnection!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    try super.setUpWithError()
    delegate = MockDelegate()
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try super.tearDownWithError()
    delegate = nil
    sut = nil
  }
  
  func testInitUDPConnectionActively() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .udp)
  }
  
  func testInitTCPConnectionActively() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .tcp)
  }
  
  func testConnectionNameChangeWhenReady() {
    let endpoint = makeLocalEndpointWithRandomPort()
    let name = endpoint.debugDescription
   
    guard let delegate = delegate else {return XCTFail()}
    let connectionReadyExpectation = XCTestExpectation(description: "发送设备查找请求")
    let callback = {
      XCTAssertTrue( delegate.connectionReadyWasCalled )
      XCTAssertEqual(self.sut.name, name)
      connectionReadyExpectation.fulfill()
    }
    delegate.connectionReadyCallback = callback
    
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
    XCTAssertNotNil(sut)
    
    wait(for: [connectionReadyExpectation], timeout: 1)
  }
  
  func testSendUDPDataWithMockConnection() {
    setSutWithUDPMockConnectionOfRandomPort()
    let testData = "testData".data(using: .utf8)
    
    sut.send(content: testData!)
    
    XCTAssertEqual(mockConnection.receiveData, testData)
  }
  
  func testStartConnection() {
    setSutWithUDPMockConnectionOfRandomPort()
    XCTAssertNotNil( mockConnection.stateUpdateHandler )
    XCTAssertTrue(mockConnection.startWasCalled)
  }
  
  func testCancel() {
    setSutWithUDPMockConnectionOfRandomPort()
    
    sut.cancel()
    
    XCTAssertTrue(mockConnection.cancelWasCalled)
  }
  
  func testShouldCallDelegateWhenConnectionStateIsFailed() {
    setSutWithUDPMockConnectionOfRandomPort()
    mockConnection.stateUpdateHandler?(.failed(NWError.posix(POSIXErrorCode(rawValue: 64)!)))
    XCTAssertTrue(delegate.connectionFailed)
  }
  
  //MARK: - Private method
  fileprivate func setSutWithUDPMockConnectionOfRandomPort() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
    mockConnection = MockConnection(endpoint: endpoint)
    sut.connection = mockConnection
    sut.startConnection()
  }
  
  fileprivate func setSutWithTCPMockConnectionOfRandomPort() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate)
    mockConnection = MockConnection(endpoint: endpoint)
    sut.connection = mockConnection
    sut.startConnection()
  }
  
  fileprivate func makeLocalEndpointWithRandomPort() ->NWEndpoint {
    let port = TestUtility.makeRandomValidPort()
    let host = "127.0.0.1"
    return NWEndpoint.hostPort(host: NWEndpoint.Host(host),
                               port: NWEndpoint.Port(rawValue: port)!)
  }
}
