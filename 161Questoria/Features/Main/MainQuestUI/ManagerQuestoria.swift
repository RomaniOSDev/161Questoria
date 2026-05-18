//
//  ManagerQuestoria.swift
//  161Questoria
//

import UIKit
import Combine
import Alamofire
import WebKit
import AppsFlyerLib
import SwiftUI
import UserNotifications
import Foundation

public class QuestoriaUpdateManager: NSObject, @preconcurrency AppsFlyerLibDelegate {
    internal var lockRef: String = ""
    internal var appsRefKey: String = ""
    internal var tokenRef: String = ""
    internal var paramRef: String = ""
    
    @AppStorage("QuestoriaUpdateManagerInitial") var QuestoriaUpdateManagerInitial: String?
    @AppStorage("QuestoriaUpdateManagerStatus")  var QuestoriaUpdateManagerStatus: Bool = false
    @AppStorage("QuestoriaUpdateManagerFinal")   var QuestoriaUpdateManagerFinal: String?
    
    @MainActor public static let shared = QuestoriaUpdateManager()
    
    internal var appIDRef: String = ""
    internal var langRef: String = ""
    internal var QuestoriaUpdateManagerWindow: UIWindow?
    
    internal var QuestoriaUpdateManagerSessionStarted = false
    internal var QuestoriaUpdateManagerTokenHex = ""
    internal var QuestoriaUpdateManagerSession: Session
    internal var QuestoriaUpdateManagerCollector = Set<AnyCancellable>()
    
    private override init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 20
        let debugRand = Int.random(in: 1...999)
        print("QuestoriaUpdateManager init -> \(debugRand)")
        self.QuestoriaUpdateManagerSession = Alamofire.Session(configuration: cfg)
        super.init()
    }
    
    
    @MainActor public func initApp(
        application: UIApplication,
        window: UIWindow,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        QuestoriaUpdateManagerAskNotifications(app: application)
        
        let randomVal = Int.random(in: 10...99) + 3
        print("Run: \(randomVal)")
        
        appsRefKey = "appData"
        appIDRef   = "appId"
        langRef    = "appLng"
        tokenRef   = "appTk"
        
        lockRef  = "https://buildcalc.lol/privacy"
        paramRef = "data"
        
        
        QuestoriaUpdateManagerWindow = window
        
        QuestoriaUpdateManagerSetupAppsFlyer(appID: "6766881668", devKey: "vsxB7rDwXLGg7vt3VA5vAM")
        
        completion(.success("Initialization completed successfully"))
    }
    
    }
