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

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isLoading {
                        LoadingView()
                    }

                    // ZStack to overlay favorite button on top of the image
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
                                Text(viewModel.product?.sale_price?.toString() ?? "")
                                Text(LocalizedStringKey.sar)
                            }
                            .customFont(weight: .semiBold, size: 14)
                            .foregroundColor(.primary())
                            
                            Spacer()
                            
                            RatingView(rating: .constant(viewModel.product?.rate?.toInt() ?? 0))
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
        .onChange(of: viewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                appRouter.togglePopupError(.alertError("", errorMessage))
            }
        }
        .onChange(of: cartViewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                appRouter.togglePopupError(.alertError("", errorMessage))
            }
        }
        .onChange(of: wishesViewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                appRouter.togglePopupError(.alertError("", errorMessage))
            }
        }
        .onAppear {
            getDetails()
        }
    }
}

#Preview {
    ProductDetailsView(viewModel: InitialViewModel(errorHandling: ErrorHandling()), productId: nil)
        .environmentObject(AppState())
}

extension ProductDetailsView {
    func getDetails() {
        viewModel.getProductDetails(id: productId ?? "")
    }
    
    func addToCart() {
        let params: [String: Any] = [
            "product_id": productId ?? "",
            "qty": 1,
        ]
        cartViewModel.addToCart(params: params, onsuccess: {
            showMessage()
        })
        cartViewModel.cartCount {
        }
    }
    
    private func showMessage() {
        let alertModel = AlertModel(
            icon: "",
            title: "",
            message: LocalizedStringKey.cartMessage,
            hasItem: false,
            item: "",
            okTitle: LocalizedStringKey.ok,
            cancelTitle: LocalizedStringKey.back,
            hidesIcon: true,
            hidesCancel: false,
            onOKAction: {
                appRouter.togglePopup(nil)
                appRouter.navigateBack()
                appState.currentPage = .cart
            },
            onCancelAction: {
                withAnimation {
                    appRouter.togglePopup(nil)
                }
            }
        )

        appRouter.togglePopup(.alert(alertModel))
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
            "pays": ""
        ]
        
        wishesViewModel.addWish(params: body) {_,_ in
            appRouter.navigateBack()
        }
    }
}
