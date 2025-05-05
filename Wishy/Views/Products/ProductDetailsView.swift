//
//  ProductDetailsView.swift
//  Wishy
//
//  Created by Karim Amsha on 1.05.2024.
//

import SwiftUI
import PopupView

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

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isLoading || viewModel.product == nil {
                        LoadingView()
                    }

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
                            withAnimation {
                                addToFavorite()
                            }
                        }) {
                            Image(systemName: viewModel.product?.isFavorite ?? false ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.product?.isFavorite ?? false ? .red : .gray)
                                .font(.title2)
                                .padding(10)
                        }
                        .background(Color.white.opacity(0.8).cornerRadius(8))
                        .padding()
                    }

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
                        
                        if viewModel.product?.type == "variable",
                           let attributes = viewModel.product?.attributes,
                           !attributes.isEmpty {

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
                                                    self.selectedName = option.name ?? ""
                                                    self.selectedSku = option.sku ?? ""
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
            }

            Spacer()

            if cartViewModel.isLoading {
                LoadingView()
            }

            CustomDivider()

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
                        appRouter.toggleAppPopup(.alertError("", "يرجى اختيار نوع المنتج قبل إضافته إلى امنياتي."))
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
            GroupListView(onSelect: { group, type in
                showAddToMyWishes.toggle()
                self.selectedGroup = group
                self.type = type ? "public" : "private"
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
            $0
                .type(.floater(verticalPadding: 60))
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .backgroundColor(Color.black.opacity(0.4))
        }
        .overlay(alertObservers)
        .onAppear {
            getDetails()
        }
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
        let body: [String: Any] = [
            "product_id": productId ?? "",
            "group_id": group_id,
            "type": type,
            "isShare": String(isShare),
            "total": viewModel.product?.sale_price ?? 0,
            "pays": "",
            "variation_name": selectedName,
            "variation_sku": selectedSku
        ]

        wishesViewModel.addWish(params: body) {_,_ in
            appRouter.navigateBack()
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

