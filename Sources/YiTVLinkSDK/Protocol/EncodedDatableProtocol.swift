//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/16.
//

import Foundation

/// 遵循此协议的struct可以根据属性排列顺序和字节数量来生成最终的Data类型，用于YiTVLink的网络数据收发
///  协议格式如下：
///   header：body数据长度（2 Bytes） + 命令字（2 Bytes）
///   body：各个属性的数据依次拼接
protocol EncodedDatableProtocol {
  var encodedData: Data { get }
}

/// 遵循此协议的struct可以获得encodeData
extension EncodedDatableProtocol {
  
  var encodedData: Data {
    let headerCMDLength = MemoryLayout<UInt16>.size
    /// 存储header中命令字及body的数据
    var data = Data()
    /// 存储body长度
    var length = 0
    
    /// 把某个类型的value转换成Data并修改长度值的通用方法
    func appendData<Value>(value: inout Value) {
      let valueData = Data(bytes: &value, count: MemoryLayout<Value>.size)
      data.append(valueData)
      /// 修改长度数据
      length += MemoryLayout<Value>.size
    }
    
    ///
    for c in Mirror(reflecting: self).children {
      switch c.value {
        /// 如果是String格式需要单独处理方法
      case is String:
        guard let stringData = (c.value as? String)?.data(using: .utf8) else { continue }
        data.append(stringData)
        length += stringData.count

      case is UInt8RawValue:
        guard var cmd = (c.value as? UInt8RawValue)?.rawValue.bigEndian else { continue }
        appendData(value: &cmd)

      case is UInt16RawValue:
        guard var cmd = (c.value as? UInt16RawValue)?.rawValue.bigEndian else { continue }
        appendData(value: &cmd)

      case is UInt32RawValue:
        guard var cmd = (c.value as? UInt32RawValue)?.rawValue.bigEndian else { continue }
        appendData(value: &cmd)

      default:
        continue
      }
    }
    
    var bodyLength = UInt16(length - headerCMDLength).bigEndian
    var encodedData = Data(bytes: &bodyLength, count: MemoryLayout<UInt16>.size)
    encodedData.append(data)
    
    return encodedData
  }
}

//MARK: - 补充协议

/// 利用UInt8用来提供1Byte属性的抽象
protocol UInt8RawValue {
  var rawValue: UInt8 { get }
}

extension UInt8: UInt8RawValue {
  public var rawValue: UInt8 {
    return self
  }
}

/// 利用UInt16用来提供2Bytes属性的抽象
protocol UInt16RawValue {
  var rawValue: UInt16 { get }
}

extension UInt16: UInt16RawValue {
  public var rawValue: UInt16 {
    return self
  }
}

/// 利用UInt32用来提供4Bytes属性的抽象
protocol UInt32RawValue {
  var rawValue: UInt32 { get }
}

extension UInt32: UInt32RawValue {
  public var rawValue: UInt32 {
    return self
  }
}
