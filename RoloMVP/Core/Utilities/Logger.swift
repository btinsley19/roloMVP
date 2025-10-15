//
//  Logger.swift
//  RoloMVP
//

import Foundation
import OSLog

extension Logger {
    private static let subsystem = "com.rolo.app"
    
    static let app = Logger(subsystem: subsystem, category: "app")
    static let services = Logger(subsystem: subsystem, category: "services")
    static let viewModels = Logger(subsystem: subsystem, category: "viewmodels")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}

