//
//
//  MainView.swift
//  PresentationLayer
//
//  Created by Martin Lukacs on 24/01/2026.
//
//

import SwiftUI

public struct MainView: View {
    @State private var viewModel = MainViewModel()

    public init() {}

    public var body: some View {
        Text("Add some view here")
    }
}

#Preview {
    MainView()
}
