//
//  PaymentWidget.swift
//  
//
//  Created by 김진규 on 2022/12/06.
//

import Foundation
import WebKit

public final class PaymentWidget: WKWebView, HandleURLResult {
    
    
    // MARK: - Properties
    private var amount: Double = 0 {
        didSet {
            guard amount != oldValue else { return }
            evaluateJavaScript("""
            updateAmount(\(amount))
            """)
        }
    }
    private let clientKey: String
    private let customerKey: String
    let options: Options?
    
    private weak var rootViewController: UIViewController?
    
    public weak var delegate: TossPaymentsDelegate?
    public weak var widgetUIDelegate: TossPaymentsWidgetUIDelegate?
    
    var updatedHeight: CGFloat = 400 {
        didSet {
            guard oldValue != updatedHeight else { return }
            widgetUIDelegate?.didUpdateHeight(self, height: updatedHeight)
            invalidateIntrinsicContentSize()
        }
    }
    
    var baseURL: URL {
        guard let urlString = options?.brandPay?.redirectURL,
              let url = URL(string: urlString) else {
            return URL(string: "https://tosspayments.com")!
        }
        return url
    }
    
    private lazy var initializeWidgetScript = WKUserScript(
        source: source,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )
    
    private lazy var source: String = {
        if let redirectURLString = self.options?.brandPay?.redirectURL {
            return """
                const widget = PaymentWidget("\(self.clientKey)", "\(self.customerKey)", {
                  brandpay: { redirectUrl: "\(redirectURLString)" }
                });
                const { updateAmount } = widget.renderPaymentMethods('#payment-method', \(amount));
                widget.renderAgreement('#agreement');
                """
        } else {
            return """
                const widget = PaymentWidget("\(self.clientKey)", "\(self.customerKey)", {
                  brandpay: { redirectUrl: "" }
                });
                const { updateAmount } = widget.renderPaymentMethods('#payment-method', \(amount));
                widget.renderAgreement('#agreement');
                """
        }
    }()
    
    // MARK: - Life Cycle
    public init(
        clientKey: String,
        customerKey: String,
        options: Options? = nil
    ) {
        self.clientKey = clientKey
        self.customerKey = customerKey
        self.options = options
        let configuration = WKWebViewConfiguration()
        super.init(frame: .zero, configuration: configuration)
        bindContentSize()
        uiDelegate = self
        navigationDelegate = self
    }
    
    public func renderPaymentMethods(amount: Double) {
        self.amount = amount
        configuration.userContentController.addUserScript(initializeWidgetScript)
        configuration.userContentController.add(RequestPaymentsMessageHandler(self), name: ScriptName.requestPayments.rawValue)
        configuration.userContentController.add(UpdateHeightMessageHandler(), name: ScriptName.updateHeight.rawValue)
        configuration.userContentController.add(RequestHTMLMessageHandler(self), name: ScriptName.requestHTML.rawValue)
        loadHTMLString(self.htmlToLoadString(shouldIncludeLicense: true), baseURL: baseURL)
    }
    
    public func updateAmount(_ amount: Double) {
        self.amount = amount
    }
    
    public override var intrinsicContentSize: CGSize {
        var size = UIScreen.main.bounds.size
        size.height = self.updatedHeight
        return size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func requestPayment(
        info: WidgetPaymentInfo,
        on rootViewController: UIViewController
    ) {
        var requestJSONObject = info.convertToPaymentInfo(amount: amount)
        requestJSONObject?["successUrl"] = WebConstants.successURL
        requestJSONObject?["failUrl"] = WebConstants.failURL
        let jsonString = requestJSONObject?.jsonString ?? ""
        
        self.rootViewController = rootViewController
        let javascriptString = """
        widget.requestPaymentForNativeSDK(\(jsonString));
        """
        guard let encodedScript = javascriptString.urlEncoded.data(using: .utf8)?.base64EncodedString() else { return }
        evaluateJavaScript(
            """
            var script = decodeURIComponent(window.atob('\(encodedScript)'));
            eval(script);
            """) { (_, error) in
                
            }
    }
    
}


// MARK: - HTML String

private extension PaymentWidget {
    
    func htmlToLoadString(shouldIncludeLicense: Bool) -> String {
        if shouldIncludeLicense {
            return htmlStringWithLicenseSectionAdded
        } else {
            return originalHtmlString
        }
    }
    
    
    /// Returns Original HTML string from Toss
    var originalHtmlString: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <title>결제하기</title>
          <script src="https://js.tosspayments.com/\(TossPaymentsEnvironment.stage)/payment-widget"></script>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        </head>
        <body style="margin:0;padding:0;overflow:hidden;">
            <div id="payment-method"></div>
        </body>
        </html>
        """
    }
    
    
    /// Returns HTML String with an added agreement div (`<div id="agreement"></div>`).
    var htmlStringWithLicenseSectionAdded: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <title>결제하기</title>
          <script src="https://js.tosspayments.com/\(TossPaymentsEnvironment.stage)/payment-widget"></script>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        </head>
        <body style="margin:0;padding:0;overflow:hidden;">
            <div id="payment-method"></div>
            <div id="agreement"></div>
        </body>
        </html>
        """
    }
    
}


// MARK: - New Agreement section logic

extension PaymentWidget {
    
    /// A custom method which compute height of an element and return a completion block with the newly computed height.
    /// - Parameter completion: A completion block wrapping the newly computed height value.
    private func computeAgreementHeight(completion: @escaping (CGFloat) -> Void) {
        self.evaluateJavaScript(
       """
        (function GetHeightWidth() {
        let elem = document.getElementById("agreement");
      return elem.offsetHeight
      })();
      """
        ) { agreementHeight, error in
            if let computedHeight = agreementHeight as? CGFloat {
                completion(computedHeight)
            }else {
                completion(0)
            }
            
        }
    }
    
    private func bindContentSize() {
        // Get the scroll view of the WKWebView
        // Add an observer to the contentSize property
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentSize), options: [.new], context: nil)
    }
    
    // An observer method to be notified when the contentSize changes
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UIScrollView.contentSize) {
            self.computeAgreementHeight { newAgreementHeight in
                self.widgetUIDelegate?.didUpdateHeight(self, height: self.updatedHeight + newAgreementHeight)
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
}

