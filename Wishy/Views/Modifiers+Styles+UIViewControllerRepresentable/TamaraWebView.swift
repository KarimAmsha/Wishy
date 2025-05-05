//
//  TamaraWebView.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import SwiftUI
import WebKit

struct TamaraWebView: UIViewRepresentable {
    @ObservedObject var viewModel: TamaraWebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        if let requestURL = URL(string: viewModel.url) {
            let request = URLRequest(url: requestURL)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var viewModel: TamaraWebViewModel

        init(viewModel: TamaraWebViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.isLoading = false
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let urlStr = url.absoluteString

            if urlStr.starts(with: viewModel.merchantURL.success) {
                viewModel.result = .success
                decisionHandler(.cancel)
                return
            }

            if urlStr.starts(with: viewModel.merchantURL.failure) {
                viewModel.result = .failure
                decisionHandler(.cancel)
                return
            }

            if urlStr.starts(with: viewModel.merchantURL.cancel) {
                viewModel.result = .cancelled
                decisionHandler(.cancel)
                return
            }

            if urlStr.starts(with: viewModel.merchantURL.notification) {
                viewModel.result = .notification
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
