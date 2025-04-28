//
//  RetailPaymentView.swift
//  Wishy
//
//  Created by Karim Amsha on 1.05.2024.
//

import SwiftUI
import goSellSDK

struct RetailPaymentView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State var total = ""
    @ObservedObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    let wishId: String?
    @StateObject private var paymentViewModel = PaymentViewModel()

    var body: some View {
        VStack {
            Image("ic_money")
                .padding(.top, 80)
            
            Text("اكتب القيمة بالريال السعودي")
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.primaryBlack())
            
            VStack(alignment: .leading) {
                TextField(LocalizedStringKey.sar, text: $total)
                    .placeholder(when: total.isEmpty) {
                        Text(LocalizedStringKey.sar)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .keyboardType(.numberPad)
                    .accentColor(.primary())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .underline()
                    .roundedBackground(cornerRadius: 12, strokeColor: .gray898989(), lineWidth: 1)
            }
            .foregroundColor(.black222020())

            Spacer()
            
            Button {
                if !total.isEmpty {
                    startPayment(amount: total.toDouble() ?? 0.0)
                } else {
                    wishesViewModel.errorMessage = "ادخل قيمة للاستمرار بالدفع!"
                }
            } label: {
                Text("الاستمرار للدفع")
            }
            .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
            .padding(.horizontal, 16)
        }
        .padding(16)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text("ساهم الان بـ قَطّة!")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onChange(of: wishesViewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                appRouter.togglePopupError(.alertError("", errorMessage))
            }
        }
        .onChange(of: paymentViewModel.errorMessage) { errorMessage in
            if !errorMessage.isEmpty {
                appRouter.togglePopupError(.alertError("", errorMessage))
            }
        }
        .onChange(of: paymentViewModel.paymentSuccess) { paymentSuccess in
            // Do something when payment is successful
            if paymentSuccess {
                payWish()
            }
        }
        .onAppear {
            GoSellSDK.mode = .production
        }
    }
}

#Preview {
    RetailPaymentView(wishId: "")
}

extension RetailPaymentView {
    func payWish() {
        let params: [String: Any] = [
            "total": total
        ]

        wishesViewModel.payWish(id: wishId ?? "", params: params) {
            appRouter.navigate(to: .paymentSuccess)
        }
    }
}

extension RetailPaymentView {
    func startPayment(amount: Double) {
        paymentViewModel.updateAmount(amount.toString())
        paymentViewModel.startPayment()
    }
}
