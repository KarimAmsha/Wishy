import SwiftUI
import OPPWAMobile

class Config: NSObject {
    static let urlScheme = "sa.com.Fazaa.Wishy.payments"
}

struct HyperpayCheckoutView: UIViewControllerRepresentable {
    let checkoutId: String
    let paymentBrands: [String]
    let onResult: (Result<String, Error>) -> Void
    var onDismiss: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let paymentProvider = OPPPaymentProvider(mode: .test)
        let checkoutSettings = OPPCheckoutSettings()
        checkoutSettings.paymentBrands = paymentBrands
        checkoutSettings.shopperResultURL = Config.urlScheme + "://payment"

        let checkoutProvider = OPPCheckoutProvider(
            paymentProvider: paymentProvider,
            checkoutID: checkoutId,
            settings: checkoutSettings
        )
        checkoutProvider?.delegate = context.coordinator
        context.coordinator.checkoutProvider = checkoutProvider

        DispatchQueue.main.async {
            checkoutProvider?.presentCheckout(
                forSubmittingTransactionCompletionHandler: { (transaction, error) in
                    context.coordinator.checkoutProvider(checkoutProvider!, didSubmitTransaction: transaction, error: error)
                },
                cancelHandler: {
                    context.coordinator.checkoutProviderDidCancel(checkoutProvider!)
                }
            )
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, OPPCheckoutProviderDelegate {
        let onResult: (Result<String, Error>) -> Void
        var onDismiss: (() -> Void)?
        weak var checkoutProvider: OPPCheckoutProvider?

        init(onResult: @escaping (Result<String, Error>) -> Void, onDismiss: (() -> Void)?) {
            self.onResult = onResult
            self.onDismiss = onDismiss
        }

        func checkoutProvider(_ checkoutProvider: OPPCheckoutProvider, didSubmitTransaction transaction: OPPTransaction?, error: Error?) {
            print("==== Hyperpay SDK Result Callback ====")
            if let error = error {
                print("Error: \(error.localizedDescription)")
                onResult(.failure(error))
                checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
                    self?.onDismiss?()
                })
            } else if let transaction = transaction {
                print("Transaction: \(transaction)")
                print("Resource Path: \(transaction.resourcePath ?? "nil")")
                print("Type: \(transaction.type.rawValue)")
                onResult(.success(transaction.resourcePath ?? ""))

                if transaction.type == .asynchronous {
                    // انتظر سفاري، لا تغلق
                } else {
                    checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
                        self?.onDismiss?()
                    })
                }
            } else {
                print("No error, no transaction -- unexpected result!")
                checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
                    self?.onDismiss?()
                })
            }
        }

        func checkoutProviderDidCancel(_ checkoutProvider: OPPCheckoutProvider) {
            let error = NSError(
                domain: "Hyperpay",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "تم الإلغاء من قبل المستخدم"]
            )
            onResult(.failure(error))
            checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
                self?.onDismiss?()
            })
        }

        func checkoutProviderDidFinishSafariViewController(_ checkoutProvider: OPPCheckoutProvider) {
            print("checkoutProviderDidFinishSafariViewController called")
            checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
                self?.onDismiss?()
            })
        }
    }
}
