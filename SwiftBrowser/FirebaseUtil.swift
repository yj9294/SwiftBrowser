//
//  FirebaseUtil.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/19.
//


import Foundation
import Firebase

class FirebaseUtil: NSObject {
    
    static func requestRemoteConfig() {
        // 获取本地配置
        if GADUtil.share.getConfig() == nil {
            let path = Bundle.main.path(forResource: "GADConfig", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                let adConfig = try JSONDecoder().decode(ADConfig.self, from: data)
                GADUtil.share.updateConfig(adConfig)
                NSLog("[Config] Read local ad config success.")
            } catch let error {
                NSLog("[Config] Read local ad config fail.\(error.localizedDescription)")
            }
        }
        
        /// 远程配置
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.fetch { [weak remoteConfig] (status, error) -> Void in
            if status == .success {
                NSLog("[Config] Config fetcher! ✅")
                remoteConfig?.activate(completion: { _, _ in
                    let keys = remoteConfig?.allKeys(from: .remote)
                    NSLog("[Config] config params = \(keys ?? [])")
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let remoteADConfig = try? JSONDecoder().decode(ADConfig.self, from: data) {
                            // 需要在主线程
                            GADUtil.share.updateConfig(remoteADConfig)
                        } else {
                            NSLog("[Config] Config config 'adConfig' is nil or config not json.")
                        }
                    }
                })
            } else {
                NSLog("[Config] config not fetcher, error = \(error?.localizedDescription ?? "")")
            }
        }
        
        /// 广告配置是否是当天的
        if GADUtil.share.isNeedCleanLimit() {
            GADUtil.share.cleanLimit()
        }
    }
    
    static func log(event: FirebaseEvent, params: [String: Any]? = nil) {
        
        if event.first {
            if UserDefaults.standard.bool(forKey: event.rawValue) == true {
                return
            } else {
                UserDefaults.standard.set(true, forKey: event.rawValue)
            }
        }
        
        #if DEBUG
        #else
        Analytics.logEvent(event.rawValue, parameters: params)
        #endif
        
        NSLog("[Event] \(event.rawValue) \(params ?? [:])")
    }
    
    static func log(property: FirebaseProPerty, value: String? = nil) {
        
        var value = value
        
        if property.first {
            if UserDefaults.standard.string(forKey: property.rawValue) != nil {
                value = UserDefaults.standard.string(forKey: property.rawValue)!
            } else {
                UserDefaults.standard.set(Locale.current.regionCode ?? "us", forKey: property.rawValue)
            }
        }
#if DEBUG
#else
        Analytics.setUserProperty(value, forName: property.rawValue)
#endif
        NSLog("[Property] \(property.rawValue) \(value ?? "")")
    }
}

enum FirebaseProPerty: String {
    /// 設備
    case local = "swiftBro_borth"
    
    var first: Bool {
        switch self {
        case .local:
            return true
        }
    }
}

enum FirebaseEvent: String {
    
    var first: Bool {
        switch self {
        case .open:
            return true
        default:
            return false
        }
    }
    
    case open = "swiftBro_lun"
    case openCold = "swiftBro_clod"
    case openHot = "swiftBro_hot"
    case homeShow = "swiftBro_impress"
    case fbClick = "swiftBro_nav"
    case search = "swiftBro_search"
    case cleanClick = "swiftBro_clean"
    case cleanSuccess = "swiftBro_cleanDone"
    case cleanAlert = "swiftBro_cleanToast"
    case tabShow = "swiftBro_showTab"
    case tabNew = "swiftBro_clickTab"
    case shareClick = "swiftBro_share"
    case copyClick = "swiftBro_copy"
    case webStart = "swiftBro_requist"
    case webSuccess = "swiftBro_load"
}

