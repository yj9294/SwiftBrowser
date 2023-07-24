//
//  Browser.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/13.
//

import Foundation
import UIKit
import WebKit

class BrowserUtil: NSObject {
    static let shared = BrowserUtil()
    var webItems:[WebViewItem] = [.navgationItem]
    
    var webItem: WebViewItem {
        webItems.filter {
            $0.isSelect == true
        }.first ?? .navgationItem
    }
    
    func removeItem(_ item: WebViewItem) {
        if item.isSelect {
            webItems = webItems.filter {
                $0 != item
            }
            webItems.first?.isSelect = true
        } else {
            webItems = webItems.filter {
                $0 != item
            }
        }
    }
    
    func clean() {
        webItems.forEach { item in
            item.view.updateStatusHandle = nil
            item.view.searchHandle = nil
            item.view.removeFromSuperview()
        }
        webItems = [.navgationItem]
    }
    
    func add(_ item: WebViewItem = .navgationItem) {
        webItem.view.removeFromSuperview()
        webItems.forEach {
            $0.isSelect = false
        }
        webItems.insert(item, at: 0)
    }
    
    func select(_ item: WebViewItem) {
        if !webItems.contains(item) {
            return
        }
        webItems.forEach {
            $0.isSelect = false
        }
        item.isSelect = true
    }
    
    func load(_ url: String) {
        webItem.loadUrl(url)
    }
    
    func stopLoad() {
        webItem.stopLoad()
    }
    
    func canGoBack() -> Bool {
        webItem.view.webView.canGoBack
    }
    
    func canGoForword() -> Bool {
        webItem.view.webView.canGoForward
    }
    
    func isLoading() -> Bool {
        webItem.view.webView.estimatedProgress > 0.0 && webItem.view.webView.estimatedProgress < 1.0
    }
    
    func url() -> String {
        webItem.view.webView.url?.absoluteString ?? ""
    }
    
    func isNavigation() -> Bool {
        webItem.isNavigation
    }
    
    func progress() -> Float {
        Float(webItem.view.webView.estimatedProgress)
    }
    
    func goBack() {
        BrowserUtil.shared.webItem.view.webView.goBack()
    }
    
    func goForword() {
        BrowserUtil.shared.webItem.view.webView.goForward()
    }
    
}

class WebViewItem: NSObject {
    
    init(view: HomeContentView, isSelect: Bool) {
        self.view = view
        self.isSelect = isSelect
    }
    var view: HomeContentView
    
    var isNavigation: Bool {
        view.webView.url == nil
    }
    var isSelect: Bool
    
    func loadUrl(_ url: String) {
        // 添加 view
        view.loadUrl(url)
    }
    
    func stopLoad() {
        view.webView.stopLoading()
    }
    
    static var navgationItem: WebViewItem {
        let view = HomeContentView.Load()
        return WebViewItem(view: view, isSelect: true)
    }
}

extension String {
    func isUrl() -> Bool {
        let url = "[a-zA-z]+://.*"
        let predicate = NSPredicate(format: "SELF MATCHES %@", url)
        return predicate.evaluate(with: self)
    }
}
