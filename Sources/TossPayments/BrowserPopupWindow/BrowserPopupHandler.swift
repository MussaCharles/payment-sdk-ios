//
//  BrowserPopupHandler.swift
//  
//
//  Created by 찰스 iOS 개발자 라이클 on 2023/04/19.
//

import Foundation
import WebKit

/// Wraps logic to handle presenting `BrowserPopupWindowController`.
protocol BrowserPopupHandler {
    
    func createPopupWindow(parentWebView: WKWebView,configuration: WKWebViewConfiguration) -> WKWebView
    
    func present(popupWebView: WKWebView)
}

// MARK: - default Implementations

extension BrowserPopupHandler {
    
    func createPopupWindow(parentWebView: WKWebView,configuration: WKWebViewConfiguration) -> WKWebView {
        
        let popupWebView = WKWebView(
            frame: CGRect(x: 0,
                          y: 0,
                          width: parentWebView.frame.width,
                          height: UIScreen.main.bounds.height),
            configuration: configuration
        )
        
        popupWebView.navigationDelegate = parentWebView.navigationDelegate
        popupWebView.uiDelegate = parentWebView.uiDelegate
        
        return popupWebView
        
    }
    
    func present(popupWebView: WKWebView) {
        guard let topViewController =  UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.visibleViewController else {return}
        
        DispatchQueue.main.async {
            topViewController.present(UINavigationController(rootViewController: BrowserPopupWindowController(popupWebView: popupWebView)), animated: true)
        }
    }
    
}
