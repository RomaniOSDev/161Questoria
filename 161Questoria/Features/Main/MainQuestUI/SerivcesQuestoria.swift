//
//  SerivcesQuestoria.swift
//  161Questoria
//

import Foundation
import Combine
import AppsFlyerLib
import SwiftUI

    extension QuestoriaUpdateManager {
    
        @MainActor public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
            let debugLocal = Int.random(in: 1...100)
            print("appsFl succes ->: \(debugLocal)")
            
            let rawData   = try! JSONSerialization.data(withJSONObject: conversionInfo, options: .fragmentsAllowed)
            let rawString = String(data: rawData, encoding: .utf8) ?? "{}"
            
            let finalJson = """
        {
            "\(appsRefKey)": \(rawString),
            "\(appIDRef)": "\(AppsFlyerLib.shared().getAppsFlyerUID() ?? "")",
            "\(langRef)": "\(Locale.current.languageCode ?? "")",
            "\(tokenRef)": "\(QuestoriaUpdateManagerTokenHex)"
        }
        """
            
            let sanitizedJson = finalJson.replacingOccurrences(of: "#", with: "")
            
            QuestoriaUpdateManager.shared.QuestoriaUpdateManagerPrivacyAndTermsReq(code: sanitizedJson) { result in
                switch result {
                case .success(let msg):
                    self.QuestoriaUpdateManagerSendNotice(name: "RemMess", message: msg)
                case .failure:
                    self.QuestoriaUpdateManagerSendNoticeError(name: "RemMess")
                }
            }
        }
        
    
    public func onConversionDataFail(_ error: any Error) {
        let dummyVal = Double.random(in: 0..<1)
        print("onConversionDataFail | Error: \(error.localizedDescription)")
        QuestoriaUpdateManagerSendNoticeError(name: "RemMess")
    }
    
    @objc func QuestoriaUpdateManagerHandleActiveSession() {
        if !QuestoriaUpdateManagerSessionStarted {
            let localValue = Int.random(in: 100...200)
            print("QuestoriaUpdateManagerHandleActiveSession -> localValue = \(localValue)")
            
            AppsFlyerLib.shared().start()
            QuestoriaUpdateManagerSessionStarted = true
        }
    }
    
    @MainActor public func QuestoriaUpdateManagerSetupAppsFlyer(appID: String, devKey: String) {
        AppsFlyerLib.shared().appleAppID                   = appID
        AppsFlyerLib.shared().appsFlyerDevKey              = devKey
        AppsFlyerLib.shared().delegate                     = self
        AppsFlyerLib.shared().disableAdvertisingIdentifier = true
        
        let sumOfKeys = appID.count + devKey.count
        print("QuestoriaUpdateManagerSetupAppsFlyer -> sumOfKeys: \(sumOfKeys)")
        
        let firstLaunchKey = "hasLaunchedBefore"
        let hasLaunched = UserDefaults.standard.bool(forKey: firstLaunchKey)
        if !hasLaunched {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
    }
    
    
    public func QuestoriaUpdateManagerAskNotifications(app: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { app.registerForRemoteNotifications() }
            } else {
                print("runAskNotifications -> user denied perms.")
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(QuestoriaUpdateManagerHandleActiveSession),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    internal func QuestoriaUpdateManagerSendNotice(name: String, message: String) {
        print("QuestoriaUpdateManagerSendNotice -> \(message.count)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": message]
            )
        }
    }
    
    internal func QuestoriaUpdateManagerSendNoticeError(name: String) {
        print("QuestoriaUpdateManagerSendNoticeError -> \(name.count * 2)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": "Error occurred"]
            )
        }
    }
    
    public func QuestoriaUpdateManagerParseAFSnippet() {
        let snippet = "{\"sxAF\":777}"
        if let data = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print("QuestoriaUpdateManagerParseAFSnippet ->\(obj)")
            } catch {
                print("runParseAFSnippet ->\(error)")
            }
        }
    }
    
    public func QuestoriaUpdateManagerIsSessionInit() -> Bool {
        print("QuestoriaUpdateManagerIsSessionInit -> \(QuestoriaUpdateManagerSessionStarted)")
        return QuestoriaUpdateManagerSessionStarted
    }
    
    public func QuestoriaUpdateManagerPartialAFCheck(_ info: [AnyHashable: Any]) {
        print("QuestoriaUpdateManagerPartialAFCheck ->\(info.count)")
    }
    
    public func QuestoriaUpdateManagerAFSmallDebug() -> String {
        let randomVal = Int.random(in: 1000...9999)
        let code = "AFDBG-\(randomVal)"
        print("QuestoriaUpdateManagerAFSmallDebug -> \(code)")
        return code
    }
    
    public func QuestoriaUpdateManagerRegisterToken(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        QuestoriaUpdateManagerTokenHex = tokenString
        
        let tokenLen = tokenString.count
        print("QuestoriaUpdateManagerRegisterToken -> tokenLen = \(tokenLen)")
    }
    
    public func QuestoriaUpdateManagerMergeStringSets(_ x: Set<String>, _ y: Set<String>) -> Set<String> {
        let merged = x.union(y)
        print("QuestoriaUpdateManagerMergeStringSets -> \(merged)")
        return merged
    }
    
    
    public func QuestoriaUpdateManagerMinimalRandCheck() {
        let val = Double.random(in: 0..<10)
        print("QuestoriaUpdateManagerMinimalRandCheck -> \(val)")
    }
        
    }
