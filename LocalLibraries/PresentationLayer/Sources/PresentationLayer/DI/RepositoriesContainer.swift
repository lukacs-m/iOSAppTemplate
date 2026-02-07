//
//  RepositoriesContainer.swift
//  iOSAppTemplate
//
//  Created by Martin Lukacs on 31/01/2026.
//

import FactoryKit
import Foundation

public final class RepositoriesContainer: SharedContainer, AutoRegistering {
    public static let shared = RepositoriesContainer()
    public let manager = ContainerManager()

    public func autoRegister() {
        manager.defaultScope = .singleton
    }
}
