//
//  PaymentWidget+WKNavigationDelegate.swift
//  
//
//  Created by 찰스 iOS 개발자 라이클 on 2023/04/19.
//

import WebKit

// MARK: - WKNavigationDelegate

// Simply adopting to WKNavigationDelegate is needed so that we can handle popup navigations using the same PaymentWidget UI. See, PaymentWidget+WKUIDelegate.swift file for more info.
extension PaymentWidget: WKNavigationDelegate {
    
    
    
}
