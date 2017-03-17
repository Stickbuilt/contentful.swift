//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper
import ObjectiveC.runtime

private var key = "ContentfulClientKey"

extension NSDictionary {
    var client: Client? {
        get {
            return objc_getAssociatedObject(self, &key) as? Client
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}


internal func determineDefaultLocale(_ json: Any) -> String {
    if let json = json as? NSDictionary, let space = json.client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return Defaults.locale
}

//internal extension String {
//
//    // TODO: Better solution for dates.
//    func toIS8601Date() -> Date? {
//        let formatter = DateFormatter()
//        formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        formatter.timeZone = TimeZone(abbreviation: "UTC")
//        if let date = formatter.date(from: self) {
//            return date
//        } else {
//            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//            if let date = formatter.date(from: self) {
//                return date
//            }
//        }
//        return nil
//    }
//}
//
//internal func convertStringsToDates(fields: [String: Any]) -> [String: Any] {
//    var fieldsWithDates = [String: Any]()
//
//    for (key, value) in fields {
//        if let date = (value as? String)?.toIS8601Date() {
//            fieldsWithDates[key] = date
//        } else {
//            fieldsWithDates[key] = value
//        }
//    }
//    return fieldsWithDates
//}

internal func parseLocalizedFields(_ json: [String: Any]) throws -> (String, [String: [String: Any]]) {
    let map = Map(mappingType: .fromJSON, JSON: json)
    var fields: [String: Any]!
    fields <- map["fields"]

    var locale: String?
    locale <- map["sys.locale"]

    var localizedFields = [String: [String: Any]]()

    // If there is a locale field, we still want to represent the field internally with a
    // localization mapping.
    if let locale = locale {
        localizedFields[locale] = fields
    } else {

        // In the case that the fields have been returned with the wildcard format `locale=*`
        // Therefore the structure of fieldsWithDates is [String: [String: Any]]
        fields.forEach { fieldName, localizableFields in
            if let fields = localizableFields as? [String: Any] {
                fields.forEach { locale, value in
                    if localizedFields[locale] == nil {
                        localizedFields[locale] = [String: Any]()
                    }
                    localizedFields[locale]?[fieldName] = value
                }
            }
        }
    }

    return (locale ?? Defaults.locale, localizedFields)
}
