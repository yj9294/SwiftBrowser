//
//  LaunchView.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/12.
//

import UIKit

class LaunchView: UIView {
    
    @IBOutlet weak var progressView: UIProgressView!
    var launched: (()->Void)? = nil
    
    var timer: Timer? = nil
    var progress = 0.0
    var duration = 13.0

    override func awakeFromNib() {
        super.awakeFromNib()
        viewDidLoad()
    }
    
    func viewDidLoad() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        progress = 0.0
        duration = 13.0
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(progressing), userInfo: nil, repeats: true)
    }
    
    
    @objc func progressing() {
        progress += 0.01 / duration
        if progress > 1.0 {
            timer?.invalidate()
            GADUtil.share.show(.interstitial) { [weak self] _ in
                if (self?.progress ?? 0) > 1.0 {
                    self?.launched?()
                }
            }
        } else {
            progressView.progress = Float(progress)
        }
        if progress > 0.3, GADUtil.share.isLoadedIngerstitalAD() {
            duration = 0.1
        }
    }
}
