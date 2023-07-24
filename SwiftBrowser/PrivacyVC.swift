//
//  PrivacyVC.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/19.
//

import UIKit

class PrivacyVC: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    var content: String = ""
    var type: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.textView.text = self.content
            self.titleLabel.text = self.type
        }
    }
    
    @IBAction func back() {
        dismiss(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
}
