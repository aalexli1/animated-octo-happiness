//
//  CollectionView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/17/25.
//

import SwiftUI

struct CollectionView: View {
    @StateObject private var gameState = GameStateManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedTab) {
                    Text("Stats").tag(0)
                    Text("Achievements").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    StatsView(stats: gameState.playerStats)
                } else {
                    AchievementsView(achievements: gameState.achievements)
                }
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        gameState.resetProgress()
                    }) {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct StatsView: View {
    let stats: PlayerStats
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatCard(title: "Total Score", value: "\(stats.totalScore)", icon: "star.fill", color: .yellow)
                
                StatCard(title: "Treasures Found", value: "\(stats.totalTreasuresFound)", icon: "shippingbox.fill", color: .orange)
                
                HStack(spacing: 15) {
                    MiniStatCard(title: "Gold", value: "\(stats.goldTreasuresFound)", color: .yellow)
                    MiniStatCard(title: "Silver", value: "\(stats.silverTreasuresFound)", color: .gray)
                    MiniStatCard(title: "Bronze", value: "\(stats.bronzeTreasuresFound)", color: .brown)
                }
                
                HStack(spacing: 15) {
                    MiniStatCard(title: "Gems", value: "\(stats.gemTreasuresFound)", color: .purple)
                    MiniStatCard(title: "Artifacts", value: "\(stats.artifactTreasuresFound)", color: .teal)
                }
                
                StatCard(title: "Sessions Played", value: "\(stats.sessionsPlayed)", icon: "gamecontroller.fill", color: .blue)
                
                StatCard(title: "Perfect Sessions", value: "\(stats.perfectSessions)", icon: "checkmark.seal.fill", color: .green)
                
                StatCard(title: "Play Time", value: "\(stats.totalPlayTimeMinutes) min", icon: "clock.fill", color: .indigo)
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AchievementsView: View {
    let achievements: [Achievement]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding()
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if achievement.isUnlocked, let date = achievement.unlockedDate {
                    Text("Unlocked: \(date, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(achievement.isUnlocked ? Color(.systemGray6) : Color(.systemGray5).opacity(0.5))
        .cornerRadius(10)
    }
}

#Preview {
    CollectionView()
}