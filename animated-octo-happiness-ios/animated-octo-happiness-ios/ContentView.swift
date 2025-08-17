//
//  ContentView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TreasureListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Treasure.self, inMemory: true)
}
