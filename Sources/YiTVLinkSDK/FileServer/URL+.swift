//
//  File 2.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Foundation
public
extension URL {
  static func serverRoot() throws -> URL {
    try FileManager.default.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false)
  }

  func visibleContents() throws -> [URL] {
    try FileManager.default.contentsOfDirectory(
      at: self,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles)
  }
}
