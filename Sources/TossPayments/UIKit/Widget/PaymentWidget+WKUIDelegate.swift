//
//  PaymentWidget+WKUIDelegate.swift
//  
//
//  Created by 찰스 iOS 개발자 라이클 on 2023/04/19.
//

import WebKit


// MARK: - WKUIDelegate

extension PaymentWidget: WKUIDelegate, BrowserPopupHandler {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let popupWebView = createPopupWindow(parentWebView: webView,configuration: configuration)
        present(popupWebView: popupWebView)
        return popupWebView
        
    }
}

