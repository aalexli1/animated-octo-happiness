//
//  EmojiSelectionView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI

struct EmojiSelectionView: View {
    @ObservedObject var viewModel: TreasureCreationViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Choose an icon for your treasure")
                    .font(.headline)
                    .padding(.top)
                
                Text("This icon will appear on the map to mark your treasure's location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Text("Selected Icon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedEmoji)
                        .font(.system(size: 80))
                        .padding()
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                                .shadow(radius: 4)
                        )
                }
                .padding()
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.selectedEmoji = emoji
                            }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedEmoji == emoji ? 
                                              Color.blue.opacity(0.2) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(viewModel.selectedEmoji == emoji ?
                                                            Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                                .scaleEffect(viewModel.selectedEmoji == emoji ? 1.1 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer(minLength: 50)
            }
        }
    }
}