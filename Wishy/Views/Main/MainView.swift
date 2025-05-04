//
//  MainView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @State var showAddOrder = false
    @State private var path = NavigationPath()
    @ObservedObject var appRouter = AppRouter()
    @ObservedObject var viewModel = InitialViewModel(errorHandling: ErrorHandling())
    @StateObject var cartViewModel = CartViewModel(errorHandling: ErrorHandling())

    var body: some View {
        NavigationStack(path: $appRouter.navPath) {
            ZStack {
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.clear)
                    .background(.white)

                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer()
                        switch appState.currentPage {
                        case .home:
                            HomeView()
                        case .explor:
                            ExplorView()
                        case .cart:
                            if settings.id == nil {
                                CustomeEmptyView()
                            } else {
                                CartView()
                            }
                        case .favourite:
                            if settings.id == nil {
                                CustomeEmptyView()
                            } else {
                                FavoriteView(viewModel: viewModel)
                            }
                        case .more:
                            if settings.id == nil {
                                CustomeEmptyView()
                            } else {
                                ProfileView()
                            }
                        }
                        
                        ZStack {
                            VStack(spacing: 0) {
                                CustomDivider()
                                
                                HStack(spacing: 4) {
                                    TabBarIcon(appState: appState, assignedPage: .home, width: geometry.size.width/6, height: geometry.size.height/30, iconName: "ic_home", tabName: LocalizedStringKey.home, isAddButton: false, isCart: false)
                                    
                                    Spacer()

                                    TabBarIcon(appState: appState, assignedPage: .explor, width: geometry.size.width/6, height: geometry.size.height/30, iconName: "ic_wishes", tabName: LocalizedStringKey.explor, isAddButton: false, count: 0, isCart: false)

                                    Spacer()

                                    TabBarIcon(appState: appState, assignedPage: .cart, width: geometry.size.width/6, height: geometry.size.height/30, iconName: "ic_cart", tabName: LocalizedStringKey.cart, isAddButton: false, isCart: true)
                                    
                                    Spacer()

                                    TabBarIcon(appState: appState, assignedPage: .favourite, width: geometry.size.width/6, height: geometry.size.height/30, iconName: "ic_category", tabName: LocalizedStringKey.favourite, isAddButton: false, isCart: false)

                                    Spacer()


                                    TabBarIcon(appState: appState, assignedPage: .more, width: geometry.size.width/6, height: geometry.size.height/30, iconName: "ic_profile", tabName: LocalizedStringKey.more, isAddButton: false, isCart: false)
                                }
                                .padding(.horizontal)
                                .frame(width: geometry.size.width, height: geometry.size.height/10)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .background(Color.background())
                .edgesIgnoringSafeArea(.bottom)
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.background(),for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .profile:
                    ProfileView()
                case .editProfile:
                    EditProfileView()
                case .changePassword:
                    EmptyView()
//                    ChangePasswordView()
                case .changePhoneNumber:
                    EmptyView()
//                    ChangePhoneNumberView()
                case .contactUs:
                    ContactUsView()
                case .rewards:
                    EmptyView()
//                    RewardsView()
                case .paymentSuccess:
                    SuccessView()
                case .constant(let item):
                    ConstantView(item: .constant(item))
                case .myOrders:
                    MyOrdersView()
                case .orderDetails(let orderID):
                    OrderDetailsView(orderID: orderID)
                case .upcomingReminders:
                    UpcomingRemindersView()
                case .productsListView(let specialCategory):
                    ProductsListView(viewModel: viewModel, specialCategory: specialCategory)
                case .productDetails(let id):
                    ProductDetailsView(viewModel: viewModel, productId: id)
                case .selectedGiftView:
                    SelectedGiftView()
                case .friendWishes(let user):
                    FriendWishesView(user: user)
                case .friendWishesListView:
                    FriendWishesListView()
                case .friendWishesDetailsView(let id):
                    FriendWishesDetailsView(wishId: id, viewModel: viewModel)
                case .retailFriendWishesView:
                    RetailFriendWishesView()
                case .retailPaymentView(let id):
                    RetailPaymentView(wishId: id)
                case .addressBook:
                    AddressBookView()
                case .addAddressBook:
                    AddAddressView()
                case .editAddressBook(let item):
                    EditAddressView(addressItem: item)
                case .addressBookDetails(let item):
                    AddressDetailsView(addressItem: item)
                case .notifications:
                    NotificationsView()
                case .checkoutView(let cartItems):
                    CheckoutView(cartItems: cartItems)
                case .productsSearchView:
                    ProductsSearchView(viewModel: viewModel)
                case .wishesView:
                    WishesView()
                case .userProducts(let id):
                    UserProductsView(viewModel: viewModel, id: id)
                case .addUserProduct:
                    AddUserProductView(viewModel: viewModel)
                case .VIPGiftView(let type):
                    VIPGiftView(viewModel: viewModel, categoryType: type)
                case .userWishes(let userId, let groupId):
                    UserWishesView(userId: userId, group_id: groupId)
                case .wishCheckOut(let id):
                    WishCheckOutView(wishId: id)
                case .walletView:
                    WalletView()
                case .explorWishView(let id):
                    ExplorWishView(wishId: id, viewModel: viewModel)
                case .myWishView(let id):
                    MyWishView(wishId: id, viewModel: viewModel)
                case .addReview(let id):
                    AddReviewView(orderId: id)
                }
            }
            .popup(isPresented: Binding<Bool>(
                get: { appRouter.activePopup != nil },
                set: { _ in appRouter.togglePopup(nil) })
            ) {
               if let popup = appRouter.activePopup {
                   switch popup {
                   case .cancelOrder(let alertModel):
                       AlertView(alertModel: alertModel)
                   case .alert(let alertModel):
                       AlertView(alertModel: alertModel)
                   case .inputAlert(let alertModelWithInput):
                       InputAlertView(alertModel: alertModelWithInput)
                   }
               }
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
            .popup(isPresented: Binding<Bool>(
                get: { appRouter.appPopup != nil },
                set: { _ in appRouter.toggleAppPopup(nil) })
            ) {
                Group {
                    if let popup = appRouter.appPopup {
                        switch popup {
                        case .alertError(let title, let message):
                            GeneralAlertToastView(title: title, message: message, type: .error)
                        case .alertSuccess(let title, let message):
                            GeneralAlertToastView(title: title, message: message, type: .success)
                        case .alertInfo(let title, let message):
                            GeneralAlertToastView(title: title, message: message, type: .info)
                        }
                    }
                }
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
        }
        .accentColor(.black)
        .environmentObject(appRouter)
    }
}

#Preview {
    MainView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
}

