//
//  CleanView.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/18.
//

import Foundation
import UIKit

class CleanView: UIView {
    
    var confirmHandle: (()->Void)? = nil
    
    func certain(_ completion: (()->Void)? = nil) {
        confirmHandle = completion
    }
    
    @IBAction func confirmAction() {
        dismissAction()
        confirmHandle?()
    }
    
    @IBAction func dismissAction() {
        UIView.animate(withDuration: 0.25, delay: 0) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}
