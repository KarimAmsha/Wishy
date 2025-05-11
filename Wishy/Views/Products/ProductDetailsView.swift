//
//  ProductDetailsView.swift
//  Wishy
//
//  Created by Karim Amsha on 1.05.2024.
//

import SwiftUI
import PopupView
import goSellSDK

struct ProductDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    @ObservedObject var viewModel: InitialViewModel
    @ObservedObject var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    let productId: String?
    @State var showAddToMyWishes = false
    @State var showRetailAlertView = false
    @State var selectedGroup: Group?
    @State var type: String?
    @StateObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    @State private var selectedOption: String?
    @State private var selectedName: String = ""
    @State private var selectedSku: String = ""
    @State private var showAddToCartPopup = false
    @State private var selectedGroupId: String = ""
    @State private var selectedIsShare: Bool = false
    @State private var showPaymentOptions = false
    @State private var exploreCost: Double = 0.0
    @StateObject var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @State private var showTamaraPayment = false
    @State private var checkoutUrl = ""
    @State var tamaraViewModel: TamaraWebViewModel? = nil
    @StateObject private var paymentViewModel = PaymentViewModel()

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isLoading || viewModel.product == nil {
                        LoadingView()
                    }

                    productImageView
                    productDetailsView
                }
            }

            Spacer()

            if cartViewModel.isLoading {
                LoadingView()
            }

            if orderViewModel.isLoading {
                LoadingView()
            }

            CustomDivider()
            actionButtons
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text(viewModel.product?.name ?? "")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .popup(isPresented: $showAddToMyWishes) {
            GroupListView(onSelect: { group, type, cost in
                showAddToMyWishes.toggle()
                self.selectedGroup = group
                self.type = type ? "public" : "private"
                self.exploreCost = cost
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
                    showRetailAlertView.toggle()
                })
            }, onCancel: {
                showAddToMyWishes.toggle()
            })
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
        .popup(isPresented: $showRetailAlertView) {
            RetailAlertView(onSelect: { isShared in
                if let group = selectedGroup, let id = group.id, let type = type {
                    addToMyWish(group_id: id, type: type, isShare: isShared)
                }
            }, onCancel: {
                showRetailAlertView.toggle()
            })
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
        .popup(isPresented: $showAddToCartPopup) {
            AddToCartPopup(isPresented: $showAddToCartPopup) {
                appState.currentPage = .cart
            }
        } customize: {
            $0.type(.floater()).position(.bottom).animation(.spring()).closeOnTapOutside(true).backgroundColor(Color.black.opacity(0.4))
        }
        .popup(isPresented: $showPaymentOptions) {
            VStack(spacing: 20) {
                Text("اختر بوابة الدفع")
                    .customFont(weight: .bold, size: 18)

                paymentButton(icon: "creditcard", label: "مدى - ابل بي") {
                    showPaymentOptions = false
                    startMadaPayment(for: selectedGroupId, isShare: selectedIsShare)
                }

                paymentButton(icon: "cart", label: "تمارا") {
                    showPaymentOptions = false
                    startTamaraCheckout(for: selectedGroupId, isShare: selectedIsShare)
                }

                Button("إلغاء") {
                    showPaymentOptions = false
                }
                .foregroundColor(.red)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .backgroundColor(Color.black.opacity(0.4))
                .useKeyboardSafeArea(true)
        }
        .onChange(of: paymentViewModel.paymentStatus) { status in
            guard let status = status else { return }

            orderViewModel.isLoading = false

            switch status {
            case .success:
                submitWish(group_id: selectedGroupId, type: "public", isShare: selectedIsShare)
            case .failed(let message):
                orderViewModel.errorMessage = message
            case .cancelled:
                orderViewModel.errorMessage = "تم إلغاء عملية الدفع"
            }
        }
        .fullScreenCover(isPresented: $showTamaraPayment) {
            if let url = URL(string: checkoutUrl) {
                SafariView(url: url) { redirectedURL in
                    handleTamaraRedirect(url: redirectedURL)
                }
            }
        }
        .fullScreenCover(isPresented: $showTamaraPayment) {
            if let url = URL(string: checkoutUrl) {
                SafariView(url: url) { redirectedURL in
                    showTamaraPayment = false
                    let result = redirectedURL.absoluteString
                    if result.contains("success") {
                        submitWish(group_id: selectedGroupId, type: "public", isShare: selectedIsShare)
                    } else if result.contains("failure") {
                        viewModel.errorMessage = "فشلت عملية الدفع عبر تمارا"
                    }
                }
            }
        }
        .overlay(alertObservers)
        .onAppear {
            getDetails()
            GoSellSDK.mode = .sandbox
        }
    }

    var productImageView: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImageView(
                width: UIScreen.main.bounds.width,
                height: 320,
                cornerRadius: 10,
                imageURL: viewModel.product?.image?.toURL(),
                placeholder: Image(systemName: "photo"),
                contentMode: .fill
            )
            .frame(maxWidth: .infinity)

            Button(action: {
                withAnimation { addToFavorite() }
            }) {
                Image(systemName: viewModel.product?.isFavorite ?? false ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.product?.isFavorite ?? false ? .red : .gray)
                    .font(.title2)
                    .padding(10)
            }
            .background(Color.white.opacity(0.8).cornerRadius(8))
            .padding()
        }
    }
    
    var productDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.product?.name ?? "")
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.primaryBlack())

            HStack {
                HStack {
                    Text(String(format: "%.2f", viewModel.product?.sale_price ?? 0))
                    Text(LocalizedStringKey.sar)
                }
                .customFont(weight: .semiBold, size: 14)
                .foregroundColor(.primary())

                Spacer()

                RatingView(rating: .constant(viewModel.product?.rate?.toInt() ?? 0))
            }

            if let attributes = viewModel.product?.attributes, !attributes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("الأنواع")
                        .customFont(weight: .bold, size: 14)
                        .foregroundColor(.primary())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(attributes.flatMap { $0.options ?? [] }, id: \ .sku) { option in
                                Text(option.name ?? "")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(selectedName == option.name ? Color.primary() : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedName == option.name ? .white : .black)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary().opacity(selectedName == option.name ? 0 : 0.4), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        selectedName = option.name ?? ""
                                        selectedSku = option.sku ?? ""
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }

            Text(viewModel.product?.description ?? "")
                .customFont(weight: .regular, size: 14)
                .foregroundColor(.primaryBlack())
        }
        .padding(.horizontal, 16)
    }
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                addToCart()
            } label: {
                HStack(spacing: 4) {
                    Image("ic_w_cart")
                    Text(LocalizedStringKey.addToCart)
                }
            }
            .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
            .padding(.horizontal, 16)

            Button {
                if let attributes = viewModel.product?.attributes, !attributes.isEmpty, selectedSku.isEmpty {
                    appRouter.toggleAppPopup(.alertError("", "يرجى اختيار نوع المنتج قبل إضافته إلى امنياتك."))
                    return
                }
                showAddToMyWishes.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image("ic_wish")
                    Text(LocalizedStringKey.addToMyWishes)
                }
            }
            .buttonStyle(PrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryLight(), foreground: .primary(), height: 48, radius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    func paymentButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
                    .customFont(weight: .bold, size: 16)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primary())
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private func handleTamaraRedirect(url: URL) {
        let urlStr = url.absoluteString
        showTamaraPayment = false

        if urlStr.contains("wishy.sa/tamara/success") {
            submitWish(group_id: selectedGroupId, type: "public", isShare: selectedIsShare)
        } else if urlStr.contains("wishy.sa/tamara/failure") {
            orderViewModel.errorMessage = "فشلت عملية الدفع"
        } else if urlStr.contains("wishy.sa/tamara/cancel") {
            orderViewModel.errorMessage = "تم إلغاء عملية الدفع"
        }

        // بغض النظر عن الحالة، أغلق الفيو
        showTamaraPayment = false
        orderViewModel.isLoading = false
    }

    func getDetails() {
        viewModel.getProductDetails(id: productId ?? "") 
    }

    func addToCart() {
        if let attributes = viewModel.product?.attributes, !attributes.isEmpty, selectedSku.isEmpty {
            appRouter.toggleAppPopup(.alertError("", "يرجى اختيار نوع المنتج قبل إضافته إلى السلة."))
            return
        }

        let params: [String: Any] = [
            "product_id": productId ?? "",
            "qty": 1,
            "variation_name": selectedName,
            "variation_sku": selectedSku
        ]
        cartViewModel.addToCart(params: params, onsuccess: {
            // handle success
            DispatchQueue.main.async {
                self.showAddToCartPopup = true
            }
        })
        cartViewModel.cartCount {
            // refresh count
        }
    }

    func addToFavorite() {
        let params: [String: Any] = [
            "product_id": productId ?? ""
        ]
        viewModel.addToFavorite(params: params) {
            getDetails()
        }
    }

    func addToMyWish(group_id: String, type: String, isShare: Bool) {
        if type == "public" {
            // خزّن القيم لنعيد استخدامها بعد الدفع
            selectedGroupId = group_id
            selectedIsShare = isShare
            showPaymentOptions = true // إظهار بوابات الدفع
            showRetailAlertView = false
            return
        }

        // إذا كانت خاصة يتم الإضافة مباشرة
        submitWish(group_id: group_id, type: type, isShare: isShare)
    }

    func submitWish(group_id: String, type: String, isShare: Bool) {
        let body: [String: Any] = [
            "product_id": productId ?? "",
            "group_id": group_id,
            "type": type, // "public" أو "private"
            "isShare": String(isShare),
            "total": viewModel.product?.sale_price ?? 0,
            "pays": "",
            "variation_name": selectedName,
            "variation_sku": selectedSku
        ]

        wishesViewModel.addWish(params: body) { _, _ in
            appRouter.navigateBack()
        }
    }

    func startMadaPayment(for groupId: String, isShare: Bool) {
        let amount = exploreCost
        orderViewModel.isLoading = true
        selectedGroupId = groupId
        selectedIsShare = isShare

        paymentViewModel.updateAmount(amount.toString())
        paymentViewModel.startPayment()
    }

    func startTamaraCheckout(for groupId: String, isShare: Bool) {
        let amount = exploreCost
        let productId = viewModel.product?.id ?? ""

        let tamaraBody = TamaraBody(
            amount: amount,
            products: [
                TamaraProduct(
                    product_id: productId,
                    variation_name: selectedName,
                    variation_sku: selectedSku,
                    qty: 1
                )
            ]
        )

        orderViewModel.isLoading = true
        selectedGroupId = groupId
        selectedIsShare = isShare

        orderViewModel.tamaraCheckout(params: tamaraBody) {
            self.checkoutUrl = orderViewModel.tamaraCheckout?.checkout_url ?? ""
            //            self.checkoutUrl = "https://raw.githack.com/KarimAmsha/my-project/main/index.html"
            
            // Initialize the Tamara view model with the new URL and merchantURL
            self.tamaraViewModel = TamaraWebViewModel(
                url: self.checkoutUrl,
                merchantURL: TamaraMerchantURL(
                    success: "https://wishy.sa/tamara/success",
                    failure: "https://wishy.sa/tamara/failure",
                    cancel: "https://wishy.sa/tamara/cancel",
                    notification: "https://wishy.sa/tamara/cancel"
                )
            )

            showTamaraPayment = true
        }
    }
    
    var alertObservers: some View {
        VStack {
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )

            MessageAlertObserverView(
                message: $cartViewModel.errorMessage,
                alertType: .constant(.error)
            )

            MessageAlertObserverView(
                message: $wishesViewModel.errorMessage,
                alertType: $wishesViewModel.alertType.orDefault(.error)
            )
            
            MessageAlertObserverView(
                message: $orderViewModel.errorMessage,
                alertType: $wishesViewModel.alertType.orDefault(.error)
            )
        }
        .opacity(0)
    }
}

struct AddToCartPopup: View {
    @Binding var isPresented: Bool
    var onGoToCart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 تمت إضافة المنتج إلى السلة")
                .customFont(weight: .bold, size: 16)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("استمرار بالتسوق")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primaryLight())
                        .foregroundColor(.primary())
                        .cornerRadius(10)
                }

                Button(action: {
                    isPresented = false
                    onGoToCart()
                }) {
                    Text("الذهاب إلى السلة")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary())
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding()
    }
}

