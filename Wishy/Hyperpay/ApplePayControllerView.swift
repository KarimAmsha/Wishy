import PassKit
import SwiftUI
import OPPWAMobile

struct ApplePayControllerView: UIViewControllerRepresentable {
    let checkoutId: String
    let amount: Double
    let onResult: (Result<String, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIViewController {
        return ApplePayContainerViewController { vc in
            context.coordinator.startApplePay(in: vc)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
        let parent: ApplePayControllerView
        private var didFinishWithResult = false

        init(parent: ApplePayControllerView) { self.parent = parent }

        func startApplePay(in viewController: UIViewController) {
            guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada]) else {
                parent.onResult(.failure(NSError(domain: "ApplePay",
                                                 code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey: "جهازك لا يدعم Apple Pay أو لا توجد بطاقة صالحة"])))
                return
            }

            let req = PKPaymentRequest()
            req.merchantIdentifier = "merchant.wishy.newlive.sa.com" // ← بدّلها لِـ Merchant ID الحقيقي
            req.supportedNetworks = [.visa, .masterCard, .mada]
            req.merchantCapabilities = .capability3DS
            req.countryCode = "SA"
            req.currencyCode = "SAR"
            req.requiredBillingContactFields = [.name, .postalAddress, .emailAddress, .phoneNumber]
            req.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "Wishy", amount: NSDecimalNumber(value: parent.amount))
            ]

            guard let controller = PKPaymentAuthorizationViewController(paymentRequest: req) else {
                parent.onResult(.failure(NSError(domain: "ApplePay",
                                                 code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey: "تعذّر إنشاء Apple Pay Sheet"])))
                return
            }
            controller.delegate = self
            viewController.present(controller, animated: true)
        }

        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                                didAuthorizePayment payment: PKPayment,
                                                handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            // في الإنتاج استخدم .live
            let provider = OPPPaymentProvider(mode: .live)

            do {
                let params = try OPPApplePayPaymentParams(checkoutID: parent.checkoutId,
                                                          tokenData: payment.token.paymentData)
                params.shopperResultURL = "sa.com.Fazaa.Wishy.payments://payment"

                let transaction = OPPTransaction(paymentParams: params)
                provider.submitTransaction(transaction) { [weak self] (t, error) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if let error = error {
                            self.didFinishWithResult = true
                            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                            self.parent.onResult(.failure(error))
                        } else {
                            // رجّع الـ resourcePath
                            self.didFinishWithResult = true
                            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                            self.parent.onResult(.success(t.resourcePath ?? ""))
                        }
                    }
                }
            } catch {
                self.didFinishWithResult = true
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                parent.onResult(.failure(error))
            }
        }

        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true) {
                // إذا ما وصّلنا نتيجة قبل (مثلاً المستخدم أغلق الشيت قبل التفويض)
                if !self.didFinishWithResult {
                    self.parent.onResult(.failure(NSError(domain: "ApplePay",
                                                          code: 1,
                                                          userInfo: [NSLocalizedDescriptionKey: "تم الإغلاق قبل إتمام العملية"])))
                }
            }
        }
    }
}

final class ApplePayContainerViewController: UIViewController {
    let onAppear: (UIViewController) -> Void
    private var hasPresented = false

    init(onAppear: @escaping (UIViewController) -> Void) {
        self.onAppear = onAppear
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasPresented {
            hasPresented = true
            onAppear(self)
        }
    }
}

////
////  ApplePayControllerView.swift
////  Wishy
////
////  Created by Karim OTHMAN on 15.07.2025.
////
//
//import PassKit
//import SwiftUI
//import OPPWAMobile
//
//struct ApplePayControllerView: UIViewControllerRepresentable {
//    let checkoutId: String
//    let amount: Double
//    let onResult: (Result<String, Error>) -> Void
//
//    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        return ApplePayContainerViewController { vc in
//            context.coordinator.startApplePay(in: vc)
//        }
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
//
//    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
//        let parent: ApplePayControllerView
//        var hasPresented = false
//
//        init(parent: ApplePayControllerView) {
//            self.parent = parent
//        }
//
//        func startApplePay(in viewController: UIViewController) {
//            guard PKPaymentAuthorizationViewController.canMakePayments() else {
//                parent.onResult(.failure(NSError(domain: "ApplePay", code: 0, userInfo: [NSLocalizedDescriptionKey: "جهازك لا يدعم Apple Pay"])))
//                return
//            }
//
//            let request = PKPaymentRequest()
//            request.merchantIdentifier = "merchant.wishy.newlive.sa.com"
//            request.supportedNetworks = [.visa, .masterCard, .mada]
//            request.merchantCapabilities = .capability3DS
//            request.countryCode = "SA"
//            request.currencyCode = "SAR"
//            request.paymentSummaryItems = [
//                PKPaymentSummaryItem(label: "Wishy", amount: NSDecimalNumber(value: parent.amount))
//            ]
//            // الحقول المطلوبة للـ billing/contact حسب تعليمات Hyperpay/Apple
//            request.requiredBillingContactFields = [.name, .postalAddress, .emailAddress, .phoneNumber]
//
//            guard let controller = PKPaymentAuthorizationViewController(paymentRequest: request) else {
//                parent.onResult(.failure(NSError(domain: "ApplePay", code: 0, userInfo: [NSLocalizedDescriptionKey: "خطأ أثناء إعداد Apple Pay"])))
//                return
//            }
//            controller.delegate = self
//            viewController.present(controller, animated: true)
//        }
//
//        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//            let provider = OPPPaymentProvider(mode: .live) // في الإنتاج استخدم .live
//
//            do {
//                let params = try OPPApplePayPaymentParams(checkoutID: parent.checkoutId, tokenData: payment.token.paymentData)
//                params.shopperResultURL = "sa.com.Fazaa.Wishy.payments://payment" // غيّرها حسب URL Scheme عندك
//
//                // ملاحظة: القيم المطلوبة مثل email/name/postalAddress تُستخرج تلقائيًا من Apple Pay وتُرسل في params
//                // لو بدك تتأكد من الحقول، اعمل logging هنا
//
//                let transaction = OPPTransaction(paymentParams: params)
//                provider.submitTransaction(transaction) { (transaction, error) in
//                    DispatchQueue.main.async {
//                        if let error = error {
//                            print("Apple Pay/Hyperpay Error: \(error.localizedDescription)")
//                            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
//                            self.parent.onResult(.failure(error))
//                        } else {
//                            print("Apple Pay/Hyperpay Success: \(transaction.resourcePath ?? "no resourcePath")")
//                            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
//                            self.parent.onResult(.success(transaction.resourcePath ?? ""))
//                        }
//                    }
//                }
//            } catch {
//                print("Apple Pay Params Error: \(error.localizedDescription)")
//                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
//                parent.onResult(.failure(error))
//            }
//        }
//
//        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
//            controller.dismiss(animated: true) {
//                // لازم ترجع الـ state عشان ما يعلق الفيو/الـ sheet في SwiftUI
//                self.parent.onResult(.failure(NSError(domain: "ApplePay", code: 1, userInfo: [NSLocalizedDescriptionKey: "تم الإلغاء من قبل المستخدم"])))
//            }
//        }
//    }
//}
//
//// UIViewController مخصص لفتح الـ Apple Pay Sheet بطريقة آمنة بعد ظهور الفيو بالكامل
//class ApplePayContainerViewController: UIViewController {
//    let onAppear: (UIViewController) -> Void
//
//    init(onAppear: @escaping (UIViewController) -> Void) {
//        self.onAppear = onAppear
//        super.init(nibName: nil, bundle: nil)
//    }
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//
//    private var hasPresented = false
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        if !hasPresented {
//            hasPresented = true
//            onAppear(self)
//        }
//    }
//}
