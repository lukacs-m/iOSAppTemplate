//
//  ServicesContainer.swift
//  iOSAppTemplate
//
//  Created by Martin Lukacs on 31/01/2026.
//

import FactoryKit
import Foundation

public final class ServicesContainer: SharedContainer, AutoRegistering {
    public static let shared = ServicesContainer()
    public let manager = ContainerManager()

    public func autoRegister() {
        manager.defaultScope = .singleton
    }
}
