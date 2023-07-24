//
//  HomeContentView.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/18.
//

import Foundation
import UIKit
import WebKit

class HomeContentView: UIView {
    // 系数
    var radio: Double {
        return self.bounds.width / 375.0
    }
    var searchHandle: ((HomeContentItem)->Void)? = nil
    var updateStatusHandle: (()->Void)? = nil
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        collectionView.register(UINib(nibName: "HomeContentCell", bundle: .main), forCellWithReuseIdentifier: "HomeContentCell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func loadUrl(_ url: String) {
        webView.isHidden = false
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), context: nil)
        if url.isUrl(), let Url = URL(string: url) {
            let request = URLRequest(url: Url)
            webView.load(request)
        } else {
            let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let reqString = "https://www.google.com/search?q=" + urlString
            self.loadUrl(reqString)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateStatus()
    }
    
    func updateStatus() {
        updateStatusHandle?()
    }
    
}

extension HomeContentView: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        updateStatusHandle?()
        return .allow
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        updateStatusHandle?()
        return .allow
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        updateStatusHandle?()
        webView.load(navigationAction.request)
        return nil
    }

}

extension HomeContentView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return HomeContentItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = HomeContentItem.allCases[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeContentCell", for: indexPath)
        if let cell = cell as? HomeContentCell {
            cell.item = item
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0 * radio
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0 * radio
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = ((self.bounds.width - 60 * radio - 20*3 * radio) / 4.0 - 5 * radio)
        let height = 62.0 * radio
        return CGSizeMake(width , height )
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = HomeContentItem.allCases[indexPath.row]
        searchHandle?(item)
        FirebaseUtil.log(event: .fbClick, params: ["bro": item.rawValue])
    }
}


class HomeContentCell: UICollectionViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    var item: HomeContentItem? = nil {
        didSet{
            icon.image = item?.icon
            title.text = item?.title
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

enum HomeContentItem: String, CaseIterable {
    case facebook, google, youtube, twitter, instagram, amazon, gmail, yahoo
    var title: String {
        self.rawValue.capitalized
    }
    var icon: UIImage {
        UIImage(named: self.rawValue) ?? UIImage()
    }
    var url: String {
        "https://www.\(self.rawValue).com"
    }
}
