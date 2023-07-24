//
//  AppExt.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/12.
//

import Foundation
import UIKit

extension UIView {
    static func Load() -> Self{
        let array = Bundle.main.loadNibNamed("\(Self.self)", owner: self)
        if let v = array?.first as? Self {
            return v
        }
        return Self()
    }
}

extension UIViewController {
    static func Load() -> Self{
        let sb = UIStoryboard(name: "Main", bundle: .main)
        let vc = sb.instantiateViewController(withIdentifier: "\(Self.self)")
        if let v = vc as? Self {
            return v
        }
        return Self()
    }
}
