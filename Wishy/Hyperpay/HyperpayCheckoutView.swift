import SwiftUI
import OPPWAMobile

class Config: NSObject {
    static let urlScheme = "sa.com.Fazaa.Wishy.payments"
}

struct HyperpayCheckoutView: UIViewControllerRepresentable {
    let checkoutId: String
    let paymentBrands: [String]
    let onResult: (Result<String, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
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
        weak var checkoutProvider: OPPCheckoutProvider?

        init(onResult: @escaping (Result<String, Error>) -> Void) {
            self.onResult = onResult
        }

        func checkoutProvider(_ checkoutProvider: OPPCheckoutProvider, didSubmitTransaction transaction: OPPTransaction?, error: Error?) {
            if let error = error {
                onResult(.failure(error))
            } else if let transaction = transaction {
                onResult(.success(transaction.resourcePath ?? ""))
            }
            checkoutProvider.dismissCheckout(animated: true, completion: nil)
        }

        func checkoutProviderDidCancel(_ checkoutProvider: OPPCheckoutProvider) {
//            onResult(.failure(NSError(domain: "تم الالغاء من قبل المستخدم", code: -1)))
            onResult(.failure("تم الالغاء من قبل المستخدم"))
            checkoutProvider.dismissCheckout(animated: true, completion: nil)
        }
    }
}
