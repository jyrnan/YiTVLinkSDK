//
//  KEYData.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/11/15.
//

import Foundation

public class KEYData: NSObject, Codable {
    override public var description: String {
        return super.description + "\n" + "x:\(x), y:\(y), z:\(w),\nspeed: \(motion)\nv:\(String(describing: text))"
    }

    @objc public var x: Int = 0
    @objc public var y: Int = 0
    @objc public var w: Int = 0
    @objc public var motion: Int = 0
    @objc public var text: String?

    @objc public init(x: Int,
                      y: Int,
                      w: Int,
                      motion: Int,
                      text: String?)
    {
        self.x = x
        self.y = y
        self.w = w
        self.motion = motion
        self.text = text    }

    override public init() {}
}
