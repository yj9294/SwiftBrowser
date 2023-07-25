//
//  ViewController.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/12.
//

import UIKit
import WebKit
import UniformTypeIdentifiers
import IQKeyboardManagerSwift
import AppTrackingTransparency

let AppUrl = "https://itunes.apple.com/cn/app/id"

class HomeVC: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var bottomCollection: UICollectionView!
    @IBOutlet weak var tabView: TabView!
    @IBOutlet weak var settingView: SettingView!
    @IBOutlet weak var homeAdView: GADNativeView!
    @IBOutlet weak var tabAdView: GADNativeView!
    var date: Date = Date()
    var homeViewAppear = false
    var tabViewAppear = false
    var homeAdImpressionTime = Date(timeIntervalSinceNow: -11)
    var tabAdImpressionTime = Date(timeIntervalSinceNow: -11)

    var isAnimating: Bool = false
    lazy var defaultRect: CGRect = {
        let width = (view.bounds.width - 48) / 2.0 - 2
        let height = 4.0 / 3.0 * width
        let x = 16.0
        let y = view.safeAreaInsets.top + 24
        let rect = CGRect(x: x, y: y + 20, width: width, height: height - 24)
        return rect
    }()
    
    lazy var launchView: LaunchView = {
        LaunchView.Load()
    }()
    
    var animationFrame: CGRect = .zero
    var browserView: HomeContentView {
        BrowserUtil.shared.webItem.view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(launchView)
        addContentView()
        launchView.launched = { [weak self] in
            self?.launched()
        }
        tabView.addHandle = { [weak self] in
            guard let self = self else {return}
            self.animationFrame = self.defaultRect
            self.addContentView()
            self.view.layoutIfNeeded()
            self.refreshBrowserView()
            FirebaseUtil.log(event: .tabNew, params: ["bro": "tab"])
            
            self.loadTabAD()
        }
        tabView.dismissHandle = {[weak self] rect in
            self?.animationFrame = rect
            self?.startTabDismissAnimation()
            self?.refreshBrowserView()
        }
        launching()
        refreshBrowserView()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.launching()
        }
        NotificationCenter.default.addObserver(forName: .nativeUpdate, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else {return}
            if let ad = noti.object as? NativeADModel {
                if self.homeViewAppear, BrowserUtil.shared.webItem.isNavigation {
                    if abs(self.homeAdImpressionTime.timeIntervalSinceNow) > 10 {
                        self.homeAdImpressionTime = Date()
                        self.homeAdView.nativeAd = ad.nativeAd
                    } else {
                        NSLog("[AD] (native) home原生广告刷新间隔10s")
                    }
                } else {
                    self.homeAdView.nativeAd = .none
                }
                if self.tabViewAppear {
                    if abs(self.tabAdImpressionTime.timeIntervalSinceNow) > 10 {
                        self.tabAdImpressionTime = Date()
                        self.tabAdView.nativeAd = ad.nativeAd
                    } else {
                        NSLog("[AD] (native) tab原生广告刷新间隔10s")
                    }
                } else {
                    self.tabAdView.nativeAd = .none
                }
            } else {
                self.homeAdView.nativeAd = .none
                self.tabAdView.nativeAd = .none
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        launchView.frame = self.view.bounds
        tabView.contentFrame = contentView.frame
        if !isAnimating {
            browserView.frame = contentView.frame
        }
    }
    
    func launching() {
        homeViewAppear = false
        launchView.isHidden = false
        launchView.viewDidLoad()
        GADUtil.share.load(.interstitial)
        GADUtil.share.load(.native)
    }
    
    func launched() {
        homeViewAppear = true
        if tabViewAppear {
            homeViewAppear = false
        }
        ATTrackingManager.requestTrackingAuthorization { _ in
        }
        launchView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.bottomCollection.reloadData()
        }
    }
    
    func loadHomeAD() {
        GADUtil.share.disappear(.native)
        self.tabViewAppear = false
        self.homeViewAppear = true
        GADUtil.share.load(.native)
        GADUtil.share.load(.interstitial)
    }
    
    func loadTabAD() {
        GADUtil.share.disappear(.native)
        self.homeViewAppear = false
        self.tabViewAppear = true
        GADUtil.share.load(.native)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtil.log(event: .homeShow)
        IQKeyboardManager.shared.enable = true
        homeViewAppear = true
        if launchView.isHidden {
            GADUtil.share.load(.interstitial)
            GADUtil.share.load(.native)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        homeViewAppear = false
        GADUtil.share.disappear(.native)
    }
    
    func refreshBrowserView() {
        browserView.searchHandle = { [weak self] item in
            self?.view.endEditing(true)
            self?.textField.text = item.url
            self?.search()
        }
        browserView.updateStatusHandle = { [weak self] in
            self?.progressView.progress = BrowserUtil.shared.progress()
            self?.progressView.isHidden = !BrowserUtil.shared.isLoading()
            self?.searchButton.isSelected = BrowserUtil.shared.isLoading()
            self?.textField.text = BrowserUtil.shared.url()
            self?.bottomCollection.reloadData()
            self?.textField.text = self?.browserView.webView.url?.absoluteString
            if BrowserUtil.shared.progress() == 0.1 {
                FirebaseUtil.log(event: .webStart)
                self?.date = Date()
            }
            if BrowserUtil.shared.progress() == 1.0 {
                let time = abs(self?.date.timeIntervalSinceNow ?? 0)
                FirebaseUtil.log(event: .webSuccess, params: ["bro": "\(ceil(time))"])
            }
        }
        searchButton.isSelected = BrowserUtil.shared.isLoading()
        bottomCollection.reloadData()
        textField.text = browserView.webView.url?.absoluteString
    }
}

extension HomeVC {
    
    @IBAction func searchAction() {
        view.endEditing(true)
        if searchButton.isSelected {
            textField.text = ""
            BrowserUtil.shared.stopLoad()
            searchButton.isSelected = !searchButton.isSelected
            return
        }
        if textField.text == nil || textField.text?.count == 0 {
            alert("Please enter your search content.")
            return
        }
        search()
        FirebaseUtil.log(event: .search, params: ["bro": textField.text!])
    }
    
    func search() {
        view.endEditing(true)
        BrowserUtil.shared.load(textField.text!)
        searchButton.isSelected = !searchButton.isSelected
        GADUtil.share.disappear(.native)
    }
    
    func goBack() {
        BrowserUtil.shared.goBack()
    }
    
    func goForword() {
        BrowserUtil.shared.goForword()
    }
    
    func goClean() {
        let clean = CleanView.Load()
        clean.alpha = 0
        view.insertSubview(clean, aboveSubview: settingView)
        UIView.animate(withDuration: 0.25, delay: 0) {
            clean.alpha = 1
        }
        clean.certain {
            self.goCleanVC()
        }
        FirebaseUtil.log(event: .cleanClick)
    }
    
    func goCleanVC() {
        let vc = CleanVC.Load()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
        vc.cleanHandle = {
            BrowserUtil.shared.clean()
            self.tabView.isAnimateCompletion = false
            self.tabView.collectionView.reloadData()
            self.refreshBrowserView()
            self.addContentView()
            FirebaseUtil.log(event: .cleanSuccess)
            FirebaseUtil.log(event: .cleanAlert)
        }
    }
    
    func goTab() {
        isAnimating = true
        startTabShowAnimate()
        FirebaseUtil.log(event: .tabShow)
    }
    
    func goSetting() {
        UIView.animate(withDuration: 0.25, delay: 0) {
            self.settingView.alpha = 1
        }
    }
}

extension HomeVC {
    @IBAction func dismissSetting() {
        UIView.animate(withDuration: 0.25, delay: 0) {
            self.settingView.alpha = 0
        }
    }
    
    @IBAction func newAction() {
        BrowserUtil.shared.add()
        self.animationFrame = self.defaultRect
        self.addContentView()
        self.view.layoutIfNeeded()
        self.refreshBrowserView()
        dismissSetting()
        FirebaseUtil.log(event: .tabNew, params: ["bro": "setting"])
        loadHomeAD()
    }
    
    @IBAction func copyAction() {
        FirebaseUtil.log(event: .copyClick )
        if !BrowserUtil.shared.webItem.isNavigation {
            UIPasteboard.general.setValue(BrowserUtil.shared.webItem.view.webView.url?.absoluteString ?? "", forPasteboardType: UTType.plainText.identifier)
            self.alert("Copied.")
            return
        }
        UIPasteboard.general.setValue("", forPasteboardType: UTType.plainText.identifier)
        alert("Copied.")
        dismissSetting()
    }
    
    @IBAction func shareAction() {
        var url = AppUrl
        if !BrowserUtil.shared.webItem.isNavigation {
            url = BrowserUtil.shared.webItem.view.webView.url?.absoluteString ?? AppUrl
        }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
        dismissSetting()
        FirebaseUtil.log(event: .shareClick)
    }
    
    @IBAction func privacyAction() {
        let vc = PrivacyVC.Load()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
        vc.type = "Privacy Policy"
        vc.content = """
The following terms and conditions (the “Terms”) govern your use of the VPN services we provide (the “Service”) and their associated website domains (the “Site”). These Terms constitute a legally binding agreement (the “Agreement”) between you and Tap VPN. (the “Tap VPN”).

Activation of your account constitutes your agreement to be bound by the Terms and a representation that you are at least eighteen (18) years of age, and that the registration information you have provided is accurate and complete.

Tap VPN may update the Terms from time to time without notice. Any changes in the Terms will be incorporated into a revised Agreement that we will post on the Site. Unless otherwise specified, such changes shall be effective when they are posted. If we make material changes to these Terms, we will aim to notify you via email or when you log in at our Site.

By using Tap VPN
You agree to comply with all applicable laws and regulations in connection with your use of this service.regulations in connection with your use of this service.
"""
        dismissSetting()
    }
    
    @IBAction func termsAction() {
        let vc = PrivacyVC.Load()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
        vc.type = "Terms of Users"
        vc.content = """
The following terms and conditions (the “Terms”) govern your use of the VPN services we provide (the “Service”) and their associated website domains (the “Site”). These Terms constitute a legally binding agreement (the “Agreement”) between you and Tap VPN. (the “Tap VPN”).

Activation of your account constitutes your agreement to be bound by the Terms and a representation that you are at least eighteen (18) years of age, and that the registration information you have provided is accurate and complete.

Tap VPN may update the Terms from time to time without notice. Any changes in the Terms will be incorporated into a revised Agreement that we will post on the Site. Unless otherwise specified, such changes shall be effective when they are posted. If we make material changes to these Terms, we will aim to notify you via email or when you log in at our Site.

By using Tap VPN
You agree to comply with all applicable laws and regulations in connection with your use of this service.regulations in connection with your use of this service.
"""
        dismissSetting()
    }
    
    @IBAction func rateAction() {
        let url = URL(string: AppUrl)
        if let url = url {
            UIApplication.shared.open(url)
        }
        dismissSetting()
    }
}

extension HomeVC {
    
    func findIndexItem() -> Int {
        var index = 0
        for (i, val) in BrowserUtil.shared.webItems.enumerated() {
            if val.isSelect {
                index = i
            }
        }
        return index
    }
    
    func startTabShowAnimate() {
        loadTabAD()
        
        let frame = getAnimationFram()
        let scale = CGAffineTransform(scaleX: frame.width / browserView.bounds.width, y: frame.height / browserView.bounds.height)
        let x = (browserView.bounds.width - frame.width) / 2.0 + browserView.frame.minX - frame.minX
        let y = (browserView.bounds.height - frame.height) / 2.0 + browserView.frame.minY - frame.minY
        let moveDown = CGAffineTransform(translationX: -x, y: -y)
        UIView.animate(withDuration: 0.35, delay: 0) {
            self.browserView.transform = scale.concatenating(moveDown)
            self.tabView.alpha = 1.0
        } completion: { _ in
            self.isAnimating = false
            self.tabView.isAnimateCompletion = true

        }
    }
    
    func startTabDismissAnimation() {
        loadHomeAD()
        
        self.view.insertSubview(self.browserView, belowSubview: self.settingView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.browserView.frame = self.contentView.frame
        }
        UIView.animate(withDuration: 0.35, delay: 0) {
            self.browserView.transform = .identity
            self.tabView.alpha = 0.0
        } completion: { _ in
            FirebaseUtil.log(event: .homeShow)
        }
    }
    
    func getAnimationFram() -> CGRect {
        if animationFrame != .zero {
            return animationFrame
        } else {
            return defaultRect
        }
    }
    
    func addContentView() {
        self.tabView.alpha = 0
        self.view.insertSubview(self.browserView, belowSubview: self.settingView)
    }
    
}

extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return HomeBottomItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = HomeBottomItem.allCases[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeBottomItemCell", for: indexPath)
        if let cell = cell as? HomeBottomItemCell {
            cell.item = item
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.bounds.width / 5.0
        return CGSize(width: width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = HomeBottomItem.allCases[indexPath.row]
        switch item {
        case .left:
            goBack()
        case .right:
            goForword()
        case .clean:
            goClean()
        case .tab:
            goTab()
        case .setting:
            goSetting()
        }
    }
}

extension HomeVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

class HomeBottomItemCell: UICollectionViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    var item: HomeBottomItem? = nil {
        didSet {
            icon.image = item?.icon
            if item == .tab {
                title.text = "\(BrowserUtil.shared.webItems.count)"
            } else {
                title.text = ""
            }
        }
    }
}

enum HomeBottomItem: String, CaseIterable {
    case left, right, clean, tab, setting
    var icon: UIImage {
        switch self {
        case .left:
            let enable = BrowserUtil.shared.canGoBack()
            return UIImage(named: self.rawValue + (!enable ? "_1" : "")) ?? UIImage()
        case .right:
            let enable = BrowserUtil.shared.canGoForword()
            return UIImage(named: self.rawValue + (!enable ? "_1" : "")) ?? UIImage()
        default :
            return UIImage(named: self.rawValue) ?? UIImage()
        }
    }
}

extension UIViewController {
    func alert(_ message: String) {
        let vc = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        self.present(vc, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vc.dismiss(animated: true)
        }
    }
}


