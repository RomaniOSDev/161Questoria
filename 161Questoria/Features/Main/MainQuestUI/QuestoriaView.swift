//
//  QuestoriaView.swift
//  161Questoria
//

import Foundation
import WebKit
import SwiftUI

    extension QuestoriaUpdateManager {
    
    public class QuestoriaUpdateManagerSceneController: UIViewController,
                                               WKNavigationDelegate,
                                               WKUIDelegate,
                                               WKScriptMessageHandler {
        
        private var mainWeb: WKWebView!
        
        public var fruitErrorURL: String!
        
        private var appOverlay: UIView?
        private var appOverlayWebView: WKWebView?
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            let config = WKWebViewConfiguration()
            config.preferences.javaScriptEnabled                     = true
            config.preferences.javaScriptCanOpenWindowsAutomatically = true
            
            let viewportScript = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            """
            let userScript = WKUserScript(
                source: viewportScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            config.userContentController.addUserScript(userScript)
            
            let noAutoplayJS = """
            (function() {
              const stopAll = () => {
                document.querySelectorAll('video, audio').forEach(m => {
                  m.autoplay = false;
                  m.removeAttribute('autoplay');
                  try { m.pause(); } catch (_) {}
                  m.muted = false;
                  if (!m.__guardedPlay) {
                    const origPlay = m.play.bind(m);
                    let allow = false;
                    const trust = () => { allow = true; setTimeout(() => { allow = false; }, 250); };
                    ['pointerdown','mousedown','touchstart','keydown'].forEach(ev =>
                      window.addEventListener(ev, trust, {capture:true, passive:true})
                    );
                    m.play = function() {
                      if (!allow) { try { m.pause(); } catch(_) {} return Promise.reject('user-gesture-required'); }
                      return origPlay();
                    };
                    m.__guardedPlay = true;
                  }
                });
              };
              // initial and on new nodes
              stopAll();
              const mo = new MutationObserver(stopAll);
              mo.observe(document.documentElement || document.body, { childList: true, subtree: true });
            })();
            """
            config.userContentController.addUserScript(
              WKUserScript(source: noAutoplayJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            )
            
            let helper = """
            (function(){
              const oOpen = XMLHttpRequest.prototype.open;
              const oSend = XMLHttpRequest.prototype.send;
              XMLHttpRequest.prototype.open = function(m,u) {
                this._url = u;
                return oOpen.apply(this, arguments);
              };
              XMLHttpRequest.prototype.send = function(b) {
                this.addEventListener('load', () => {
                  if (this._url && this._url.includes('/profile/identification/diia')) {
                    try {
                      const j = JSON.parse(this.responseText);
                      const data = j.data || {};
                      const link = data.url || data.secondary_url;
                      if (link) {
                        window.webkit.messageHandlers.link.postMessage(link);
                      }
                    } catch(e) {
                      console.error('XHR hook parse error', e);
                    }
                  }
                });
            
                return oSend.apply(this, arguments);
              };
            
            
            try {
              (function () {
                // --- track in-flight network so we can "wait until response comes" ---
                var __inflight = 0;
                function __maybeCommit() {
                  if (__pendingMain && !__paymentSeen && __inflight === 0) {
                    try { location.assign(__pendingMain); } catch (_) {}
                    __pendingMain = null;
                  }
                }

                var __oSend = XMLHttpRequest.prototype.send;
                XMLHttpRequest.prototype.send = function (body) {
                  __inflight++;
                  this.addEventListener('loadend', function () {
                    __inflight--;
                    __maybeCommit();
                  });
                  return __oSend.apply(this, arguments);
                };

                var __oFetch = window.fetch ? window.fetch.bind(window) : null;
                if (__oFetch) {
                  window.fetch = function () {
                    __inflight++;
                    return __oFetch.apply(this, arguments)
                      .finally(function () { __inflight--; __maybeCommit(); });
                  };
                }

                var __pendingMain = null;   // candidate URL to open in main
                var __paymentSeen = false;  // set to true once a payment popup is triggered

                var PAY_RE = /(?:^|[?&])purchaseurl(?:=|%3D)/i;

                window.open = function (url) {
                  var s = ""
                  try {
                    s = (typeof url === "string") ? url
                      : (url && typeof url.href === "string") ? url.href
                      : String(url || "")
                  } catch (_) {}

                  if (PAY_RE.test(s) &&
                      window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.newWindow) {
                    __paymentSeen = true
                    __pendingMain = null // cancel any queued redirect
                    try { window.webkit.messageHandlers.newWindow.postMessage(s) } catch (e) {}
                    return null // popup handled natively
                  }

                  __pendingMain = s

                  __maybeCommit()
                  return null // we handle navigation ourselves
                };
              })();
            } catch (e) {}
             
            })();
            """
            config.userContentController.addUserScript(
                WKUserScript(source: helper,
                             injectionTime: .atDocumentStart,
                             forMainFrameOnly: false)
            )

            let nativePopupPatch = """
            (function(){
              try {
                function str(u){ try {
                  return (typeof u==='string') ? u
                    : (u && typeof u.href==='string') ? u.href
                    : String(u||'');
                } catch(_) { return ''; } }

                function openViaAnchor(url) {
                  var s = str(url);
                  var a = document.createElement('a');
                  a.href = s;
                  a.target = '_blank'; // keep opener relationship
                  a.rel = 'noopener';  // optional; remove if opener is required by provider
                  a.style.display = 'none';
                  document.documentElement.appendChild(a);
                  a.click();
                  a.remove();
                  // return a lightweight fake Window so site code that checks truthiness continues
                  return {
                    closed: false,
                    focus: function(){},
                    close: function(){ this.closed = true; },
                    location: {
                      set href(u){ try { openViaAnchor(u); } catch(_){} },
                      assign: function(u){ try { openViaAnchor(u); } catch(_){} },
                      replace: function(u){ try { openViaAnchor(u); } catch(_){} }
                    }
                  };
                }

                var prev = window.open;
                window.open = function(url, target, features){
                  try { return openViaAnchor(url); }
                  catch(e){ try { return prev.apply(this, arguments); } catch(_) { return null; } }
                };
              } catch(_) {}
            })();
            """
            config.userContentController.addUserScript(
                WKUserScript(source: nativePopupPatch,
                             injectionTime: .atDocumentStart,
                             forMainFrameOnly: false)
            )

            config.userContentController.add(self, name: "link")
            config.userContentController.add(self, name: "newWindow")
            
            mainWeb = WKWebView(frame: .zero, configuration: config)
            mainWeb.isOpaque                            = false
            mainWeb.backgroundColor                     = .white
            mainWeb.uiDelegate                          = self
            mainWeb.navigationDelegate                  = self
            mainWeb.allowsBackForwardNavigationGestures = true
            
            view.addSubview(mainWeb)
            mainWeb.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                mainWeb.topAnchor.constraint(equalTo: view.topAnchor),
                mainWeb.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                mainWeb.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mainWeb.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            
            loadContent(fruitErrorURL)
            
            let localDouble = Double.random(in: 0..<10)
            print("runSceneController -> localDouble: \(localDouble)")
        }
        
        public func QuestoriaUpdateManagerAnalyzeScrollBehavior() {
            let bounce = mainWeb.scrollView.bounces
            print("runAnalyzeScrollBehavior -> bounces: \(bounce)")
        }
        
        private func loadContent(_ urlString: String) {
            guard let decoded = urlString.removingPercentEncoding,
                  let finalURL = URL(string: decoded) else { return }
            mainWeb.load(URLRequest(url: finalURL))
        }
        
        public func userContentController(_ ucc: WKUserContentController,
                                          didReceive message: WKScriptMessage) {
            if message.name == "link",
               let href = message.body as? String,
               let decoded = href.removingPercentEncoding,
               let url = URL(string: decoded) {
                mainWeb.load(URLRequest(url: url))
            } else if message.name == "newWindow",
                      let raw = message.body as? String {
                if let purchaseURL = extractWindowOverlayUrl(from: raw) {
                    showWindowOverlay(with: purchaseURL)
                    return
                }
                let decoded = raw.removingPercentEncoding ?? raw
                if !decoded.isEmpty, decoded.lowercased() != "about:blank" {
                    if let base = mainWeb.url,
                       let absolute = URL(string: decoded, relativeTo: base)?.absoluteURL {
                        mainWeb.load(URLRequest(url: absolute))
                        return
                    } else if let absolute = URL(string: decoded) {
                        mainWeb.load(URLRequest(url: absolute))
                        return
                    }
                }
            } else {
                if let str = message.body as? String {
                    let decoded = str.removingPercentEncoding ?? str
                    if !decoded.isEmpty, decoded.lowercased() != "about:blank" {
                        if let base = mainWeb.url,
                           let absolute = URL(string: decoded, relativeTo: base)?.absoluteURL {
                            mainWeb.load(URLRequest(url: absolute))
                        } else if let absolute = URL(string: decoded) {
                            mainWeb.load(URLRequest(url: absolute))
                        }
                    }
                }
            }
        }
        
        public override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationItem.largeTitleDisplayMode = .never
            navigationController?.isNavigationBarHidden = true
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if QuestoriaUpdateManager.shared.QuestoriaUpdateManagerFinal == nil {
                let finalUrl = webView.url?.absoluteString ?? ""
                QuestoriaUpdateManager.shared.QuestoriaUpdateManagerFinal = finalUrl
                print("webView(didFinish) -> finalUrlLen = \(finalUrl.count)")

            }
        }
        
        public func webView(_ webView: WKWebView,
                            createWebViewWith config: WKWebViewConfiguration,
                            for navAction: WKNavigationAction,
                            windowFeatures: WKWindowFeatures) -> WKWebView? {
            let popup = WKWebView(frame: .zero, configuration: config)
            popup.navigationDelegate                  = self
            popup.uiDelegate                          = self
            popup.allowsBackForwardNavigationGestures = true
            
            presentPopupInOverlay(popup)
            return popup
        }
        
        private func presentPopupInOverlay(_ popup: WKWebView) {
            if appOverlay != nil { closeWindowOverlay() }
            
            let overlay = UIView()
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            
            popup.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(popup)
            NSLayoutConstraint.activate([
                popup.topAnchor.constraint(equalTo: overlay.topAnchor),
                popup.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
                popup.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
                popup.trailingAnchor.constraint(equalTo: overlay.trailingAnchor)
            ])
            
            let close = makeCloseButton()
            close.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(close)
            NSLayoutConstraint.activate([
                close.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 12),
                close.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
                close.widthAnchor.constraint(equalToConstant: 36),
                close.heightAnchor.constraint(equalToConstant: 36)
            ])
            
            self.appOverlay = overlay
            self.appOverlayWebView = popup
        }
        
        public func QuestoriaUpdateManagerReloadAfterDelay(_ seconds: Double) {
            print("runReloadAfterDelay -> scheduling in \(seconds) s.")
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                print("runReloadAfterDelay -> reloading now.")
                self.mainWeb.reload()
            }
        }
        
        public func QuestoriaUpdateManagerLogWebOffset() {
            let offset = mainWeb.scrollView.contentOffset
            print("runLogWebOffset -> \(offset)")
        }
        
        public func QuestoriaUpdateManagerToggleNavBar() {
            let hidden = navigationController?.isNavigationBarHidden ?? false
            navigationController?.setNavigationBarHidden(!hidden, animated: true)
            print("runToggleNavBar -> from \(hidden) to \(!hidden)")
        }
        
        private func extractWindowOverlayUrl(from source: String) -> URL? {
            let pattern = #"purchaseUrl=([^&]+)"#
            if let range = source.range(of: pattern, options: .regularExpression) {
                var encoded = String(source[range])
                if encoded.hasPrefix("purchaseUrl=") {
                    encoded.removeFirst("purchaseUrl=".count)
                }
                let decodedOnce  = encoded.removingPercentEncoding ?? encoded
                let decodedTwice = decodedOnce.removingPercentEncoding ?? decodedOnce
                if let url = URL(string: decodedTwice) {
                    return url
                }
            }
            
            if let maybeURL = URL(string: source) {
                if source.contains("purchaseUrl=") { return maybeURL }
            }
            return nil
        }
        
        private func makeCloseButton() -> UIButton {
            let btn = UIButton(type: .system)
            if #available(iOS 13.0, *) {
                btn.setImage(UIImage(systemName: "xmark"), for: .normal)
            } else {
                btn.setTitle("✕", for: .normal)
            }
            btn.tintColor = .white
            btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            btn.layer.cornerRadius = 18
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            btn.addTarget(self, action: #selector(closeWindowOverlay), for: .touchUpInside)
            return btn
        }
        
        private func showWindowOverlay(with url: URL) {
            if appOverlay != nil { closeWindowOverlay() }
            
            let overlay = UIView()
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            
            let cfg = WKWebViewConfiguration()
            cfg.preferences.javaScriptEnabled = true
            cfg.preferences.javaScriptCanOpenWindowsAutomatically = true
            cfg.processPool = mainWeb.configuration.processPool
            cfg.websiteDataStore = mainWeb.configuration.websiteDataStore

            let wv = WKWebView(frame: .zero, configuration: cfg)
            wv.navigationDelegate = self
            wv.uiDelegate = self
            wv.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(wv)
            NSLayoutConstraint.activate([
                wv.topAnchor.constraint(equalTo: overlay.topAnchor),
                wv.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
                wv.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
                wv.trailingAnchor.constraint(equalTo: overlay.trailingAnchor)
            ])
            wv.load(URLRequest(url: url))
            
            let close = makeCloseButton()
            close.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(close)
            NSLayoutConstraint.activate([
                close.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 12),
                close.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
                close.widthAnchor.constraint(equalToConstant: 36),
                close.heightAnchor.constraint(equalToConstant: 36)
            ])
            
            self.appOverlay = overlay
            self.appOverlayWebView = wv
        }
        
        @objc private func closeWindowOverlay() {
            appOverlayWebView?.stopLoading()
            appOverlay?.removeFromSuperview()
            appOverlayWebView = nil
            appOverlay = nil
        }
    }
}
