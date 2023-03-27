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
    func encodeData(from value: Any) -> Data? {
      switch value {
      /// 如果是String格式需要单独处理方法
      case is String:
        return (value as? String)?.data(using: .utf8)

      case is OneByteRawValue:
        guard var value = (value as? OneByteRawValue)?.rawValue.bigEndian else { return nil }
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))

      case is TwoBytesRawValue:
        guard var value = (value as? TwoBytesRawValue)?.rawValue.bigEndian else { return nil }
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))

      case is FourBytesRawValue:
        guard var value = (value as? FourBytesRawValue)?.rawValue.bigEndian else { return nil }
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))

      default:
        return nil
      }
    }

    let headerCMDLength = MemoryLayout<UInt16>.size

    let data = Mirror(reflecting: self)
      .children
      .compactMap { encodeData(from: $0.value) }
      .reduce(into: Data()) { $0.append($1) }

    var bodyLength = UInt16(data.count - headerCMDLength).bigEndian
    var encodedData = Data(bytes: &bodyLength, count: MemoryLayout<UInt16>.size)
    encodedData.append(data)

    return encodedData
  }
}

// MARK: - 补充协议

/// 利用UInt8用来提供1Byte属性的抽象
protocol OneByteRawValue {
  var rawValue: UInt8 { get }
}

extension UInt8: OneByteRawValue {
  public var rawValue: UInt8 {
    return self
  }
}

/// 利用UInt16用来提供2Bytes属性的抽象
protocol TwoBytesRawValue {
  var rawValue: UInt16 { get }
}

extension UInt16: TwoBytesRawValue {
  public var rawValue: UInt16 {
    return self
  }
}

/// 利用UInt32用来提供4Bytes属性的抽象
protocol FourBytesRawValue {
  var rawValue: UInt32 { get }
}

extension UInt32: FourBytesRawValue {
  public var rawValue: UInt32 {
    return self
  }
}
