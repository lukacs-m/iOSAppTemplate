//
//  AppRouter.swift
//  PresentationLayer
//
//  Created by Martin Lukacs on 31/01/2026.
//

import Foundation
import SwiftUI

enum RouterDestination: Hashable {
    case empty
}

public enum SheetDestination: Hashable, Identifiable {
    public var id: Self {
        self
    }

    case empty
}

public enum FullScreenDestination: Hashable, Identifiable {
    public var id: Self {
        self
    }

    case empty
}

@Observable
final class AppRouter {
    var path = NavigationPath()
    var presentedSheet: SheetDestination?
    var presentedFullscreenSheet: FullScreenDestination?

    var noSheetDisplayed: Bool {
        presentedSheet == nil && presentedFullscreenSheet == nil
    }

    func navigate(to: RouterDestination) {
        path.append(to)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func back(to numberOfScreen: Int = 1) {
        path.removeLast(numberOfScreen)
    }
}

public extension View {
    var routingProvided: some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
            case .empty:
                EmptyView()
            }
        }
    }

    func sheetDestinations(_ destination: Binding<SheetDestination?>) -> some View {
        sheet(item: destination) { destination in
            switch destination {
            case .empty:
                EmptyView()
            }
        }
    }

    #if os(iOS)
        func fullScreenDestination(_ destination: Binding<FullScreenDestination?>) -> some View {
            fullScreenCover(item: destination) { destination in
                switch destination {
                case .empty:
                    EmptyView()
                }
            }
        }
    #endif
}
