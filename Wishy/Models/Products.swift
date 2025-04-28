//
//  Products.swift
//  Wishy
//
//  Created by Karim Amsha on 20.05.2024.
//

import SwiftUI

struct Products: Codable, Hashable {
    let rate: Double?
    let isFromUser: Bool?
    let id: String?
    let sale_price: Double?
    let image: String?
    let createat: String?
    let category_id: String?
    let special_id: String?
    let isOffer: Bool?
    let isDeleted: Bool?
    let favorite_id: String?
    let name: String?
    let description: String?
    let arName: String?
    let enName: String?
    let arDescription: String?
    let enDescription: String?
    let by: String?
    let qty: Int?
    let total: Double?
    let totalDiscount: Double?

    var isFavorite: Bool {
        return favorite_id != nil && !favorite_id!.isEmpty
    }

    var formattedCreateDate: String? {
        guard let createat = createat else { return nil }
        return Utilities.convertDateStringToDate(stringDate: createat, outputFormat: "yyyy-MM-dd")
    }

    enum CodingKeys: String, CodingKey {
        case rate
        case isFromUser
        case id = "_id"
        case sale_price
        case image
        case createat
        case category_id
        case special_id
        case isOffer
        case isDeleted
        case favorite_id
        case name
        case description
        case arName
        case enName
        case arDescription
        case enDescription
        case by
        case qty
        case total
        case totalDiscount

    }
    
    // Computed property to return name based on app language
    var localizedName: String? {
        let languageCode = Locale.current.language.languageCode?.identifier
        switch languageCode {
        case "ar":
            return arName
        default:
            return enName
        }
    }
    
    var localizedDescription: String? {
        let languageCode = Locale.current.language.languageCode?.identifier
        switch languageCode {
        case "ar":
            return arDescription
        default:
            return enDescription
        }
    }    
}

struct By: Codable, Hashable {
    let token: String?
    let isDeleted: Bool?
    let cities: [String]?
    let id: String?
    let image: String?
    let email: String?
    let password: String?
    let name: String?
    let isBlock: Bool?
    let orderPercentage: Int?
    let rate: Double?
    let details: String?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case token, isDeleted, cities
        case id = "_id"
        case image, email, password, name, isBlock, orderPercentage, rate, details
        case v = "__v"
    }
}

struct OrderProducts: Codable, Hashable {
    let rate: Double?
    let id: String?
    let sale_price: Double?
    let image: String?
    let createat: String?
    let category_id: String?
    let special_id: String?
    let isOffer: Bool?
    let isDeleted: Bool?
    let favorite_id: String?
    let name: String?
    let description: String?
    let arName: String?
    let enName: String?
    let arDescription: String?
    let enDescription: String?
    let by: String?
    let qty: Int?

    var formattedCreateDate: String? {
        guard let createat = createat else { return nil }
        return Utilities.convertDateStringToDate(stringDate: createat, outputFormat: "yyyy-MM-dd")
    }

    enum CodingKeys: String, CodingKey {
        case rate
        case id = "_id"
        case sale_price
        case image
        case createat
        case category_id
        case special_id
        case isOffer
        case isDeleted
        case favorite_id
        case name
        case description
        case arName
        case enName
        case arDescription
        case enDescription
        case by
        case qty
    }
    
    // Computed property to return name based on app language
    var localizedName: String? {
        let languageCode = Locale.current.language.languageCode?.identifier
        switch languageCode {
        case "ar":
            return arName
        default:
            return enName
        }
    }
    
    var localizedDescription: String? {
        let languageCode = Locale.current.language.languageCode?.identifier
        switch languageCode {
        case "ar":
            return arDescription
        default:
            return enDescription
        }
    }
}

