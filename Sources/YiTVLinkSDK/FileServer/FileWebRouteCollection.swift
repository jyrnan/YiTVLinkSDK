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
    ///  否则会回复400错误，Vipor不支持Range bytes=0-0参数,
    ///  解决方法是将request headers里面的bytes=0-0 改成bytes=0-1
    if req.headers.contains(where: { name, value in
      name == "Range" && value == "bytes=0-0"
    }) {
      req.headers.replaceOrAdd(name: "Range", value: "bytes=0-1")
    }
    
    print("\nReq Description:\n----\n",req.description, "\n----\n")
    print("\nReq headers:\n----\n", req.headers, "\n----\n")
    
    /// 获取共享文件的本地路径
    guard let fileURL = server?.sharingFileURLs[filename] else {return Response(status: .notFound)}
        
    /// 返回数据
    let response = req.fileio.streamFile(at: fileURL.path)
    
    print("\nResponse description:\n----\n", response.description, "\n----\n")
    print("\nResponse headers:\n----\n", response.headers, "\n----\n")
    
    return response
  }
}

