import Foundation

struct APIConfig {
    static let baseURL = "https://wishyapp-f54346d0b493.herokuapp.com/api/mobile"
    static let checkoutEndpoint = "\(baseURL)/hyperpay"        // لطلب رقم الدفع checkoutId
    static let statusEndpoint = "\(baseURL)/check-hyperpay"    // للتأكد من الدفع
}

// موديل الريسبونس عند طلب رقم دفع جديد
struct HyperpayCheckoutResponse: Codable {
    let status: Bool
    let code: Int?
    let message: String?
    let items: HyperpayCheckoutItem?
}

struct HyperpayCheckoutItem: Codable {
    let result: ResultInfo?
    let buildNumber: String?
    let timestamp: String?
    let ndc: String?
    let id: String? // checkoutId
    let payment_order_id: String?
    let order_no: String?
    let amount: String?
}

// جزء الريزولت الداخلي
struct ResultInfo: Codable {
    let code: String?
    let description: String?
}

// موديل استجابة التحقق من حالة الدفع
struct HyperpayCheckStatusResponse: Codable {
    let status: Bool
    let code: Int?
    let message: String?
    let items: HyperpayCheckStatusItem?
}

struct HyperpayCheckStatusItem: Codable {
    let result: ResultInfo?
    let buildNumber: String?
    let timestamp: String?
    let ndc: String?
}

class HyperPaymentViewModel: ObservableObject {
    @Published var isShowingCheckout = false
    @Published var checkoutId: String?
    @Published var paymentStatus: String?
    @Published var errorMessage: String?
    @Published var lastCheckoutDetails: HyperpayCheckoutItem? // لتخزين آخر التفاصيل في الواجهة إذا احتجتها
    var userSettings = UserSettings.shared

    /// لطلب رقم الدفع (checkoutId) من الباك اند
    func requestCheckoutId(amount: Double, brandType: Int = 1, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: APIConfig.checkoutEndpoint) else {
            completion(nil)
            return
        }
        guard let token = userSettings.token else {
            DispatchQueue.main.async {
                self.errorMessage = "يرجى تسجيل الدخول أولاً"
                completion(nil)
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
//        let bodyString = "type=\(brandType)&amount=\(amount)"
        let amountStr: String = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        }()
        let bodyString = "type=\(brandType)&amount=\(amountStr)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue("ar", forHTTPHeaderField: "Accept-Language")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "لم يتم الحصول على بيانات"
                    completion(nil)
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(HyperpayCheckoutResponse.self, from: data)
                if decoded.status, let checkoutId = decoded.items?.id {
                    print("1111 \(decoded.items)")
                    print("checkoutId sent to SDK: \(checkoutId)")
                    print("brands sent: \(brandType)")

                    DispatchQueue.main.async {
                        self.checkoutId = checkoutId
                        self.isShowingCheckout = true
                        self.lastCheckoutDetails = decoded.items
                        completion(checkoutId)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = decoded.message ?? "فشل في الحصول على رقم الدفع"
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "خطأ في التحويل البرمجي للبيانات"
                    completion(nil)
                }
            }
        }.resume()
    }

    /// للتحقق من الدفع بعد إنهاء العملية
//    func checkPaymentStatus(hyperpayId: String, brandType: Int = 1, completion: @escaping (Bool, HyperpayCheckStatusResponse?) -> Void) {
//        guard let url = URL(string: "\(APIConfig.statusEndpoint)?hyperpay_id=\(hyperpayId)") else {
//            completion(false, nil)
//            return
//        }
//        guard let token = userSettings.token else {
//            DispatchQueue.main.async {
//                self.errorMessage = "يرجى تسجيل الدخول أولاً"
//                completion(false, nil)
//            }
//            return
//        }
//        print("urlurl \(url)")
//        print("hyperpayId \(hyperpayId)")
//        print("brandType \(brandType)")
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        let bodyString = "type=\(brandType)"
//        request.httpBody = bodyString.data(using: .utf8)
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        request.setValue(token, forHTTPHeaderField: "token")
//        request.setValue("ar", forHTTPHeaderField: "Accept-Language")
//
//        URLSession.shared.dataTask(with: request) { data, _, _ in
//            guard let data = data else {
//                DispatchQueue.main.async {
//                    self.errorMessage = "لم يتم الحصول على بيانات الحالة"
//                    completion(false, nil)
//                }
//                return
//            }
//            do {
//                let decoded = try JSONDecoder().decode(HyperpayCheckStatusResponse.self, from: data)
//                print("2222 \(decoded.items)")
//
//                // مثال على فحص النتيجة والكود بوضوح
//                let successCodes = ["000.000.000", "000.100.110", "000.200.000", "000.200.100"]
//                if decoded.status, let code = decoded.items?.result?.code, successCodes.contains(code) {
//                    DispatchQueue.main.async {
//                        self.paymentStatus = "success"
//                        completion(true, decoded)
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.errorMessage = decoded.items?.result?.description ?? decoded.message ?? "فشلت عملية الدفع"
//                        self.paymentStatus = "fail"
//                        completion(false, decoded)
//                    }
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "خطأ في التحقق من الدفع"
//                    self.paymentStatus = "fail"
//                    completion(false, nil)
//                }
//            }
//        }.resume()
//    }
    
    private func isHyperpaySuccess(_ code: String) -> Bool {
        let pattern = #"""
        ^(
            (000\.000\.|000\.100\.1|000\.[36]) |
            (000\.400\.0[^3]|000\.400\.100)    |
            (000\.200)                         |
            (800\.400\.5|100\.400\.500)
        )
        """#
        let compact = pattern.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        return code.range(of: compact, options: .regularExpression) != nil
    }
    
    func checkPaymentStatus(hyperpayId: String,
                            brandType: Int = 1,
                            completion: @escaping (Bool, HyperpayCheckStatusResponse?) -> Void) {
        
        let encId = hyperpayId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hyperpayId
        
        // رابط الـ API (فيه فقط الـ hyperpay_id بالـ query)
        guard let url = URL(string: "\(APIConfig.statusEndpoint)?hyperpay_id=\(encId)") else {
            completion(false, nil)
            return
        }
        guard let token = userSettings.token else {
            DispatchQueue.main.async {
                self.errorMessage = "يرجى تسجيل الدخول أولاً"
                completion(false, nil)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // ⬅️ POST
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ar", forHTTPHeaderField: "Accept-Language")
        
        // البودي يحتوي على type فقط
        let body: [String: Any] = [
            "type": brandType
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "لم يتم الحصول على بيانات الحالة"
                    completion(false, nil)
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(HyperpayCheckStatusResponse.self, from: data)
                
                let statusFromBackend = decoded.status
                let statusFromCode = self.isHyperpaySuccess(decoded.items?.result?.code ?? "")
                
                if statusFromBackend || statusFromCode {
                    self.paymentStatus = "success"
                    completion(true, decoded)
                } else {
                    self.errorMessage = decoded.items?.result?.description ?? decoded.message ?? "فشلت عملية الدفع"
                    self.paymentStatus = "fail"
                    completion(false, decoded)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "خطأ في التحقق من الدفع"
                    self.paymentStatus = "fail"
                    completion(false, nil)
                }
            }
        }.resume()
    }
}
