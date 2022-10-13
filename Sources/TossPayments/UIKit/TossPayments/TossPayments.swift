#if canImport(UIKit)

import UIKit

public class TossPayments {
    private let clientKey: String
    public var delegate: TossPaymentsDelegate?
    public init(
        clientKey: String
    ) {
        self.clientKey = clientKey
    }
    public func requestPayment(
        _ paymentMethod: PaymentMethod,
        _ 결제정보: 결제정보,
        on rootViewController: UIViewController
    ) {
        let service = TossPaymentsService(
            clientKey: clientKey,
            paymentMethod: paymentMethod,
            결제정보: 결제정보
        )
        let viewController = TossPaymentsViewController(service: service)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        service.successURLHandler = { url in
            viewController.dismiss(animated: true) {
                self.handleSuccessURL(url)
            }
        }
        service.failURLHandler = { url in
            viewController.dismiss(animated: true) {
                self.handleFailURL(url)
            }
        }
        
        rootViewController.present(navigationController, animated: true)
    }
    
    public func requestCardPayment(
        _ 카드결제정보: 카드결제정보,
        on rootViewController: UIViewController
    ) {
        requestPayment(.카드, 카드결제정보, on: rootViewController)
    }
    
    public func requestTransferPayment(
        _ 계좌이체결제정보: 계좌이체결제정보,
        on rootViewController: UIViewController
    ) {
        requestPayment(.계좌이체, 계좌이체결제정보, on: rootViewController)
    }
    
    public func requestVirtualAccountPayment(
        _ 가상계좌결제정보: 가상계좌결제정보,
        on rootViewController: UIViewController
    ) {
        requestPayment(.가상계좌, 가상계좌결제정보, on: rootViewController)
    }

    public func requestMobilePhonePayment(
        _ 휴대폰결제정보: 휴대폰결제정보,
        on rootViewController: UIViewController
    ) {
        requestPayment(.휴대폰, 휴대폰결제정보, on: rootViewController)
    }

    public func requestGiftCertificatePayment(
        _ 상품권결제수단: 상품권결제수단,
        _ 상품권결제정보: 상품권결제정보,
        on rootViewController: UIViewController
    ) {
        let 결제수단 = 상품권결제수단.paymentMethod
        requestPayment(결제수단, 상품권결제정보, on: rootViewController)
    }
}

private extension TossPayments {
    func handleSuccessURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let paymentKey = components.query(for: "paymentKey")
        let orderId = components.query(for: "orderId")
        let amount = Int64(components.query(for: "amount")) ?? 0
        delegate?.didSucceedRequestPayments(paymentKey: paymentKey, orderId: orderId, amount: amount)
    }
    
    func handleFailURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let errorCode = components.query(for: "code")
        let errorMessage = components.query(for: "message")
        let orderId = components.query(for: "orderId")
        delegate?.didFailRequestPayments(errorCode: errorCode, errorMessage: errorMessage, orderId: orderId)
    }
}

#endif
