//
//  TreasureRowView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI

struct TreasureRowView: View {
    let treasure: Treasure
    
    var body: some View {
        HStack {
            Image(systemName: treasure.isCollected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(treasure.isCollected ? .green : .secondary)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(treasure.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(treasure.treasureDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text("\(treasure.latitude, specifier: "%.4f"), \(treasure.longitude, specifier: "%.4f")")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(treasure.timestamp, style: .date)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        TreasureRowView(treasure: Treasure.preview)
    }
}