//
//  YMLNWConnectionTests.swift
//
//
//  Created by jyrnan on 2023/3/18.
//

import Network
import XCTest
@testable import YiTVLinkSDK

final class YMLNWConnectionTests: XCTestCase {
  var sut: YMLNWConnection!
  var mockDelegate: MockYMLNWConnectionDelegate!
  var mockNWConnection: MockNWConnection!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    try super.setUpWithError()
    mockDelegate = MockYMLNWConnectionDelegate()
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try super.tearDownWithError()
    mockNWConnection = nil
    mockDelegate = nil
    sut = nil
  }
  
  // MARK: - Private methods
  
  fileprivate func setSutWithUDPMockConnectionMockDelegationRandomPort() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: mockDelegate, type: .udp)
    mockNWConnection = MockNWConnection(endpoint: endpoint)
    sut.connection = mockNWConnection
    sut.startConnection()
  }
  
  fileprivate func setSutWithTCPMockConnectionMockDelegationRandomPort() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: mockDelegate)
    mockNWConnection = MockNWConnection(endpoint: endpoint)
    sut.connection = mockNWConnection
    sut.startConnection()
  }
  
  fileprivate func makeLocalEndpointWithRandomPort() -> NWEndpoint {
    let port = TestUtility.makeRandomValidPort()
    let host = "127.0.0.1"
    return NWEndpoint.hostPort(host: NWEndpoint.Host(host),
                               port: NWEndpoint.Port(rawValue: port)!)
  }
  
  // MARK: - Test methods
  
  func testInitUDPConnectionActively() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: mockDelegate, type: .udp)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .udp)
    XCTAssertNotNil(sut.connection)
  }
  
  func testInitTCPConnectionActively() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: mockDelegate)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .tcp)
    XCTAssertNotNil(sut.connection)
  }
  
  func testInitBroadcastConnectionActively() {
    let endpoint = makeLocalEndpointWithRandomPort()
    sut = YMLNWConnection(endpoint: endpoint, delegate: mockDelegate, type: .broadcast)
    
    XCTAssertTrue(sut.initiatedConnection)
    XCTAssertEqual(sut.type, .broadcast)
    
    do {
      _ = try XCTUnwrap(sut.connection)
      XCTAssertTrue(sut.parameters.allowLocalEndpointReuse)
      XCTAssertEqual(sut.parameters.requiredInterfaceType, .wifi)
    } catch { XCTFail() }
  }
  
  func testStartConnection() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    XCTAssertNotNil(mockNWConnection.stateUpdateHandler)
    XCTAssertTrue(mockNWConnection.startWasCalled)
    XCTAssertNotNil(sut.heartbeatTimer)
  }

  func testCancel() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    sut.cancel()
    XCTAssertNil(sut.connection)
    XCTAssertTrue(mockNWConnection.cancelWasCalled)
  }
  
  // MARK: - Test StateHandler
  
  func testUDPNWConnectionStateIsReady() {
    let endpoint = makeLocalEndpointWithRandomPort()
    let name = endpoint.debugDescription
   
    guard let delegate = mockDelegate else { return XCTFail() }
    let connectionReadyExpectation = XCTestExpectation(description: "连接应该就绪")
    let callback = {
      XCTAssertTrue(delegate.connectionReadyWasCalled)
      XCTAssertEqual(self.sut.name, name)
      connectionReadyExpectation.fulfill()
    }
    delegate.connectionReadyCallback = callback
    
    sut = YMLNWConnection(endpoint: endpoint, delegate: delegate, type: .udp)
  
    XCTAssertNotNil(sut)
    
    wait(for: [connectionReadyExpectation], timeout: 2)
  }
  
  func testShouldCallDelegateWhenConnectionStateIsReady() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    guard let delegate = mockDelegate else { return XCTFail() }
    mockNWConnection.stateUpdateHandler?(.ready)
    XCTAssertTrue(delegate.connectionReadyWasCalled)
  }
  
  func testShouldSetReceiveHandlerWhenConnectionStateIsReady() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    XCTAssertNil(mockNWConnection.receiveMessageCompletion)
    mockNWConnection.stateUpdateHandler?(.ready)
    XCTAssertNotNil(mockNWConnection.receiveMessageCompletion)
  }
  
  func testShouldSetReceiveHandlerWhenTCPConnectionStateIsReady() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    XCTAssertNil(mockNWConnection.receiveCompletion)
    mockNWConnection.stateUpdateHandler?(.ready)
    XCTAssertNotNil(mockNWConnection.receiveCompletion)
  }

  func testShouldCallDelegateWhenConnectionStateIsFailed() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.failed(NWError.posix(POSIXErrorCode(rawValue: 64)!)))
    XCTAssertTrue(mockDelegate.connectionFailedWasCalled)
  }
  
  func testShouldCallDelegateWhenConnectionStateIsCancelled() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.cancelled)
    XCTAssertTrue(mockDelegate.connectionFailedWasCalled)
  }
  
  // MARK: - Send Tests

  func testSend() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    let testData = "testData".data(using: .utf8)
    sut.send(content: testData!)
    
    XCTAssertEqual(mockNWConnection.sentData, testData)
    if let sendCompletion = mockNWConnection.sendCompletion, case .contentProcessed(let completion) = sendCompletion {
      completion(NWError.sampleTestError)
    }
  }
  
  func testSendUDPCompletionWithError() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    let testData = "testData".data(using: .utf8)
    sut.send(content: testData!)
    
    if let sendCompletion = mockNWConnection.sendCompletion, case .contentProcessed(let completion) = sendCompletion {
      completion(NWError.sampleTestError)
    }
    XCTAssertNotNil(mockDelegate.connectionError)
    XCTAssertEqual(mockDelegate.connectionError, NWError.sampleTestError)
  }
  
  func testSendTCPDataCompletionWithError() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    let testData = "testData".data(using: .utf8)
    sut.send(content: testData!)
    
    if let sendCompletion = mockNWConnection.sendCompletion, case .contentProcessed(let completion) = sendCompletion {
      completion(NWError.sampleTestError)
    }
    XCTAssertNotNil(mockDelegate.connectionError)
    XCTAssertEqual(mockDelegate.connectionError, NWError.sampleTestError)
  }
  
  // MARK: - Receive Tests

  func testReceiveByMessage() {
    setSutWithUDPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.ready) // 确保设置好receive方法
    
    let testData = TestData().encodedData
    mockNWConnection.receiveMessageCompletion?(testData, nil, true, nil)
    XCTAssertEqual(mockDelegate.receiveMessageContent, testData)
    XCTAssertNotNil(mockNWConnection.receiveMessageCompletion)
  }
  
  func testReceiveByStream() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.ready) // 确保设置好receive方法
    
    let testData = TestData().encodedData
    /// 这里需要注意：模拟发送TCP数据需要按照接受的方式分两次来发送
    /// 这里需要按照receive方法分两次发送，先发头部4字节，再发剩余部分
    mockNWConnection.receiveCompletion?(testData[0 ..< 4], nil, false, nil)
    mockNWConnection.receiveCompletion?(testData[4...], nil, false, nil)
    XCTAssertEqual(mockDelegate.receiveMessageContent, testData)
    XCTAssertNotNil(mockNWConnection.receiveCompletion)
  }
  
  func testReceiveHeatBeatEchoShouldNotDeliverToDelegate() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.ready) // 确保设置好receive方法
    
    let testData = EchoHeartBeat().encodedData
    mockNWConnection.receiveCompletion?(testData, nil, false, nil)
    
    XCTAssertNil(mockDelegate.receiveMessageContent)
    XCTAssertNotNil(mockNWConnection.receiveCompletion)
  }
  
  func testReceiveNobodyPacketShouldDeliverToDelegate() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.ready) // 确保设置好receive方法
    
    let testData = HeartBeat().encodedData
    mockNWConnection.receiveCompletion?(testData, nil, false, nil)
    
    XCTAssertEqual(mockDelegate.receiveMessageContent, testData)
    XCTAssertNotNil(mockNWConnection.receiveCompletion)
  }
  
  func testReceiveAndIsCompleteConnectionShouldCancel() {
    setSutWithTCPMockConnectionMockDelegationRandomPort()
    mockNWConnection.stateUpdateHandler?(.ready) // 确保设置好receive方法
    
    let testData = TestData().encodedData
    mockNWConnection.receiveCompletion?(testData, nil, true, nil)
    
    XCTAssertNil(mockDelegate.receiveMessageContent) // 代理收不到数据
    XCTAssertTrue(mockNWConnection.cancelWasCalled) // connection被cancel
  }
}
