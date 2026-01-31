//
//  AppErrors.swift
//  CommonLayer
//
//  Created by Martin Lukacs on 24/01/2026.
//

import Foundation

public enum AppErrors: Error, LocalizedError {
    case unknown(underlying: (any Error)?)
}

public extension AppErrors {
     var errorDescription: String? {
        switch self {
        case let .unknown(underlyingError):
            if let underlyingError {
                return "Unknown error: \(underlyingError.localizedDescription)"
            } else {
                return "An unknown error occured"
            }
        }
    }
}
