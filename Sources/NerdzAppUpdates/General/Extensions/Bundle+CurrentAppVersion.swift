//
//  File.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

extension Bundle {
    var currentAppVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
