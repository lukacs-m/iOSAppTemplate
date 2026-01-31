//
//  ToolingContainer.swift
//  iOSAppTemplate
//
//  Created by Martin Lukacs on 31/01/2026.
//

import FactoryKit
import Foundation

public final class ToolingContainer: SharedContainer, AutoRegistering {
    public static let shared = ToolingContainer()
    public let manager = ContainerManager()

    public func autoRegister() {
        manager.defaultScope = .singleton
    }
}
