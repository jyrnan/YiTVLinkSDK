//
//  Message.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2023/1/9.
//

import Foundation

enum DataType: String, Codable {
    case remoteControl
    case string
}

enum Message: Codable {
    case remoteControl(_ remoteControl: RemoteControl)
    case string(_ string: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dataType = try container.decode(DataType.self, forKey: .type)
        let contentStr = try container.decode(String.self, forKey: .data)
        
        
        switch dataType {
        case .remoteControl:
            let json = contentStr.data(using: .utf8)!
            self = .remoteControl(try JSONDecoder().decode(RemoteControl.self, from: json))
        case .string:
            self = .string(contentStr)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .remoteControl(let value):
            let typeStr = String(describing: type(of: value))
            try container.encode(typeStr, forKey: .type)
            
            let json = try JSONEncoder().encode(value)
            let contentStr = String(data: json, encoding: .utf8)
            try container.encode(contentStr, forKey: .data)
            
        case .string(let value):
            try container.encode("String", forKey: .type)
            try container.encode(value, forKey: .data)
        }
    }
}

struct MessageWrapper<T:Codable> : Codable {
    var type: String
    var data: String
    
    init?(value: T) {
        self.type = String(describing: Swift.type(of: value))
        
        guard let valueData = try? JSONEncoder().encode(value), let dataStr = String(data: valueData, encoding: .utf8) else {return nil}
        self.data = dataStr
    }
}

