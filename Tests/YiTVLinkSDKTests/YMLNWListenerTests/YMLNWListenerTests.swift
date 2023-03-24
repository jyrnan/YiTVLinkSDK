//
//  YMLNWListenerTests.swift
//
//
//  Created by jyrnan on 2023/3/23.
//

import Network
import XCTest
@testable import YiTVLinkSDK

final class YMLNWListenerTests: XCTestCase {
  var sut: YMLNWListener!
  var mockDelegate: MockYMLNWListenerDelegate!
  var mockListener: MockNWListener!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    try super.setUpWithError()
    mockDelegate = MockYMLNWListenerDelegate()
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try super.tearDownWithError()
    mockListener = nil
    mockDelegate = nil
    sut = nil
  }
  
  // MARK: - Private methods

  private func makeSutWithMockDelegateAndTCPMockListenerOnRandomPort() {
    let port = TestUtility.makeRandomValidPort()
    sut = YMLNWListener(on: port, delegate: mockDelegate)
    
    mockListener = MockNWListener()
    sut.listener = mockListener
    sut.startListening()
  }
  
  // MARK: - Test methods

  func testInit() {
    let port = TestUtility.makeRandomValidPort()
    sut = YMLNWListener(on: port, delegate: mockDelegate, type: .udp)
    
    XCTAssertEqual(sut.port, port)
    XCTAssertTrue(sut.connectionsByID.isEmpty)
    XCTAssertEqual(sut.type, .udp)
  }
  
  // 可能这个测试必要性不大
  func testStartListening() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    XCTAssertNotNil(sut.listener?.stateUpdateHandler)
    XCTAssertNotNil(sut.listener?.newConnectionHandler)
    XCTAssertTrue(mockListener.startWasCalled)
  }
  
  func testStopListening() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    sut.stopListening()
    
    XCTAssertTrue(mockListener.cancelWasCalled)
    XCTAssertNil(sut.listener)
    XCTAssertTrue(sut.connectionsByID.isEmpty)
  }
  
  // MARK: - State Handler
  
  func testDelegateShouldBeCalledWhenListenerStateIsReady() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    mockListener.stateUpdateHandler?(.ready)
    
    XCTAssertTrue(mockDelegate.ListenerReadyWasCalled)
  }
  
  func testDelegateShouldBeCalledWhenListenerStateIsFailed() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    mockListener.stateUpdateHandler?(.failed(NWError.sampleTestError))
    
    XCTAssertEqual(mockDelegate.displayAdvertiseError, NWError.sampleTestError)
    XCTAssertTrue(mockDelegate.ListenerFailedWasCalled)
    XCTAssertNil(sut.listener)
  }
  
  func testDelegateShouldBeCalledWhenListenerStateIsWaiting() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    mockListener.stateUpdateHandler?(.waiting(NWError.sampleTestError))
    
    XCTAssertEqual(mockDelegate.displayAdvertiseError, NWError.sampleTestError)
  }
  
  func testDelegateShouldBeCalledWhenListenerStateIsCancelled() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    
    mockListener.stateUpdateHandler?(.cancelled)
    
    XCTAssertTrue(mockDelegate.ListenerFailedWasCalled)
  }
  
  // MARK: - New Connection Handler
  
  func testNewConnectionHandler() {
    makeSutWithMockDelegateAndTCPMockListenerOnRandomPort()
    let newConnection = NWConnection(host: NWEndpoint.Host("127.0.0.1"), port: NWEndpoint.Port(rawValue: 8888)!, using: .tcp)
    mockListener.newConnectionHandler?(newConnection)
    
    XCTAssertFalse(sut.connectionsByID.isEmpty)
    /// 保存的YMLNWConnection应该type和Listener一致
    XCTAssertEqual(sut.connectionsByID.values.first?.type, .tcp)
  }
  
  //MARK: - sendTo
  func testSendTo() {
    let port = TestUtility.makeRandomValidPort()
    sut = YMLNWListener(on: port, delegate: mockDelegate)
    
    let mockConnection = MockNWConnection(endpoint: NWEndpoint.hostPort(host: NWEndpoint.Host("127.0.0.1"), port: 8888))
    let connection = YMLNWConnection(connection: mockConnection, delegate: sut) //??
    mockConnection.stateUpdateHandler?(mockConnection.state)
    
    let id = connection.id
    sut.connectionsByID[id] = connection
    
    let testData = TestData().encodedData
    
    sut.sendTo(id: id, content: testData)
    mockConnection.receiveCompletion?(testData, nil, false, nil)
    
    XCTAssertNotNil(mockConnection.sentData)
    XCTAssertEqual(mockConnection.sentData, testData)
    
  }
  
  //MARK: - Delegate Methods
  
  func testConformToYMLNWConnectionDelegateConnectionReady() {
    makeSutWithNewMockConnectionOnLocalRandomPort()
    // connectionId应该是保存在YMLNWListener中connection字典库中的YMLNWConnection的id
    // 这里通过first获取是考虑测试环境中这是唯一的YMLNWConnection
    guard let connectionId = sut.connectionsByID.keys.first else {XCTFail(); return}
    
    XCTAssertTrue(mockDelegate.connectionReadyWasCalled)
    XCTAssertEqual(mockDelegate.connectionId, connectionId)
  }
  
  func testConformToYMLNWConnectionDelegateConnectionFailed() {
    makeSutWithNewMockConnectionOnLocalRandomPort()
    // connectionId应该是保存在YMLNWListener中connection字典库中的YMLNWConnection的id
    // 这里通过first获取是考虑测试环境中这是唯一的YMLNWConnection
    guard let connectionId = sut.connectionsByID.keys.first, let mockConnection = sut.connectionsByID[connectionId]?.connection as? MockNWConnection else {XCTFail(); return}
    mockConnection.stateUpdateHandler?(.failed(NWError.sampleTestError))
   
    XCTAssertTrue(mockDelegate.connectionFailedWasCalled)
    XCTAssertEqual(mockDelegate.connectionId, connectionId)
  }
  
  func testConformToYMLNWConnectionDelegateReceivedMessageMethod() {
    makeSutWithNewMockConnectionOnLocalRandomPort()
    guard let mockConnection = sut.connectionsByID.values.first?.connection as? MockNWConnection else {XCTFail(); return}
    let testData = TestData().encodedData
    
    //这里需要注意：模拟发送TCP数据需要按照接受的方式分两次来发送
    mockConnection.receiveCompletion?(testData[0..<4], nil, false, nil)
    mockConnection.receiveCompletion?(testData[4...], nil, false, nil)
    
    XCTAssertEqual(mockDelegate.receiveMessageContent, testData)
    XCTAssertTrue(mockDelegate.connectionReadyWasCalled)
    
  }
  
  func testConformToYMLNWConnectionDelegateConnectionError() {
    makeSutWithNewMockConnectionOnLocalRandomPort()
    // connectionId应该是保存在YMLNWListener中connection字典库中的YMLNWConnection的id
    // 这里通过first获取是考虑测试环境中这是唯一的YMLNWConnection
    guard let connectionId = sut.connectionsByID.keys.first, let mockConnection = sut.connectionsByID[connectionId]?.connection as? MockNWConnection else {XCTFail(); return}
    mockConnection.stateUpdateHandler?(.failed(NWError.sampleTestError))
   
    XCTAssertEqual(mockDelegate.connectionError, NWError.sampleTestError)
  }
 
  
  private func makeSutWithNewMockConnectionOnLocalRandomPort() {
    let port = TestUtility.makeRandomValidPort()
    sut = YMLNWListener(on: port, delegate: mockDelegate)
    
    let endpoint = TestUtility.makeEndpointOnLocalRandomPort()
    let mockConnection = MockNWConnection(endpoint: endpoint)
    
    let connection = YMLNWConnection(connection: mockConnection, delegate: sut)
    mockConnection.stateUpdateHandler?(.ready) //手动设置MockConnection的状态成.ready,这样会设置想应receive方法
    
    let id = connection.id
    sut.connectionsByID[id] = connection
  }
}
