//
//  TamaraWebViewModel.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import Foundation
import Combine
import WebKit

struct TamaraMerchantURL {
    let success: String
    let failure: String
    let cancel: String
    let notification: String
}

class TamaraWebViewModel: ObservableObject {
    @Published var webView = WKWebView()
    @Published var url: String
    @Published var isLoading: Bool = true
    @Published var result: ResultType? = nil

    let merchantURL: TamaraMerchantURL

    enum ResultType {
        case success
        case failure
        case cancelled
        case notification
    }

    init(url: String, merchantURL: TamaraMerchantURL) {
        self.url = url
        self.merchantURL = merchantURL

        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        self.webView = WKWebView(frame: .zero, configuration: config)
    }
}
