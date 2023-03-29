//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Foundation
  /// 获取本机Wi-Fi的IP地址
  /// - Returns: IP address of WiFi interface (en0) as a String, or `nil`
func getWiFiAddress() -> String? {
    var address: String?
            
    // Get list of all interfaces on the local machine:
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddr) == 0 {
      var ptr = ifaddr
      while ptr != nil {
        let flags = Int32((ptr?.pointee.ifa_flags)!)
        var addr = ptr!.pointee.ifa_addr.pointee
                
        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
          if addr.sa_family == UInt8(AF_INET) // || addr?.sa_family == UInt8(AF_INET6)
          {
            if String(cString: ptr!.pointee.ifa_name) == "en0" {
              // Convert interface address to a human readable string:
              var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
              if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                             nil, socklen_t(0), NI_NUMERICHOST) == 0
              {
                address = String(validatingUTF8: hostname)
              }
            }
          }
        }
        ptr = ptr?.pointee.ifa_next
      }

      freeifaddrs(ifaddr)
    }
    return address
  }

