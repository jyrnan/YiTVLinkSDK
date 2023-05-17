//
//  File.swift
//
//
//  Created by jyrnan on 2023/4/8.
//

import Foundation
import Network
import NetworkExtension

protocol YMLNWMonitorDelegate: AnyObject {
  func wifiStatusDidChanged(status: Network.NWPath.Status)
}

class YMLNWMonitor {
  private let queue = DispatchQueue(label: "YMLNWConnectivityMonitor")
  private let monitor: NWPathMonitor
  
  weak var delegate: YMLNWMonitorDelegate?
  
  init(delegate: YMLNWMonitorDelegate) {
    self.monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    self.delegate = delegate
    
    startMonitoring()
  }
  
  func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      print(#line, #function, path.debugDescription, "\n")
      
      delegate?.wifiStatusDidChanged(status: path.status)
    }
    monitor.start(queue: queue)
  }
  
  func stopMonitoring() {
    monitor.cancel()
  }
}
