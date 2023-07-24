//
//  AppUtil.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/12.
//

import Foundation
import UIKit

class AppUtil: NSObject {
    static let shared = AppUtil()
    var appEnterbackground = false
    var isLauching = false
    var rootVC: UIViewController? = nil
    var rootView: UIView? = nil
    var width: CGFloat {
        rootView?.bounds.width ?? 0.0
    }
    var height: CGFloat {
        rootView?.bounds.height ?? 0.0
    }
}
