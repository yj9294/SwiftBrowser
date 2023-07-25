//
//  CleanVC.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/18.
//

import UIKit

class CleanVC: UIViewController {
    
    @IBOutlet weak var animationView: UIImageView!
    
    var cleanHandle:(()->Void)? = nil
    var timer: Timer? = nil
    var progress: Double = 0.0
    var duration = 13.0

    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timeDecrease), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimate()
    }
    
    @objc func timeDecrease() {
        progress += 0.01 / duration
        if progress > 1.0 {
            timer?.invalidate()
            dismiss()
        }
        if progress > 0.3, GADUtil.share.isLoadedIngerstitalAD() {
            duration = 0.01
        }
    }

    func startAnimate() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = Double.pi * 2
        animation.duration = 2.0
        animation.isCumulative = true
        animation.repeatCount = 10000
        animation.autoreverses = false
        animationView.layer.add(animation, forKey: "xxx")
        
    }
    
    func stopAnimate() {
        animationView.layer.removeAllAnimations()
    }
    
    func dismiss() {
        GADUtil.share.show(.interstitial) { [weak self] _ in
            guard let self = self else {return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dismiss(animated: true) {
                    self.cleanHandle?()
                }
            }
        }
    }
}
