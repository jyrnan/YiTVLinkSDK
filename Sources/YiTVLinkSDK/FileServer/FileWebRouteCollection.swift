//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Vapor

struct FileWebRouteCollection: RouteCollection {
  weak var server: FileServer?
  
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: rootViewHandler)
    routes.get(":filename", use: downloadFileHandler)
  }

  func rootViewHandler(_ req: Request) async throws -> String {
    return "Welcome to YiTVLink"
  }

  func downloadFileHandler(_ req: Request) throws -> Response {
    guard let filename = req.parameters.get("filename") else {
      throw Abort(.badRequest)
    }
    
    /// 下载中心的下载请求头里面有这个选项，需要去除掉
    ///  否则会回复400错误，莫非Vipor不支持Range参数？
    req.headers.remove(name: "Range")
    
    print("\nReq Decription:\n----\n",req.description, "\n----\n")
    print("\nReq headers:\n----\n", req.headers, "\n----\n")
    
    /// 获取共享文件的本地路径
    guard let fileURL = server?.sharingFileURLs[filename] else {return Response(status: .notFound)}
    
    /// 返回数据
    let response = req.fileio.streamFile(at: fileURL.path)
//    print(response.headers["Content-Length"])
//    let length = response.headers["Content-Length"]
//    response.headers.add(name: "Content-Length", value: length.first!)
    
    print("\nResponse description:\n----\n", response.description, "\n----\n")
    print("\nResponse headers:\n----\n", response.headers, "\n----\n")
    
    return response
  }
}

