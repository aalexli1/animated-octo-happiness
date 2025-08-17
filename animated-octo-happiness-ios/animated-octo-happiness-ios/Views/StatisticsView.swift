//
//  StatisticsView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var statistics: GameStatistics? {
        persistenceManager.currentProfile?.statistics
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = statistics {
                        OverviewSection(stats: stats)
                        
                        ProgressSection(stats: stats)
                        
                        DifficultyChartSection(stats: stats)
                        
                        AchievementsSection(stats: stats)
                        
                        ActivitySection(stats: stats)
                    } else {
                        ContentUnavailableView(
                            "No Statistics",
                            systemImage: "chart.bar.fill",
                            description: Text("Start finding treasures to see your statistics!")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct OverviewSection: View {
    let stats: GameStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Treasures Found",
                    value: "\(stats.totalTreasuresFound)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Created",
                    value: "\(stats.totalTreasuresCreated)",
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Total Points",
                    value: "\(stats.totalPoints)",
                    icon: "trophy.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Play Time",
                    value: stats.formattedPlayTime,
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
    }
}

struct ProgressSection: View {
    let stats: GameStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                ProgressRow(
                    label: "Current Streak",
                    value: "\(stats.currentStreak) days",
                    progress: Double(stats.currentStreak) / 30.0,
                    color: .purple
                )
                
                ProgressRow(
                    label: "Distance Traveled",
                    value: stats.formattedDistance,
                    progress: min(stats.distanceTraveled / 10000, 1.0),
                    color: .blue
                )
                
                ProgressRow(
                    label: "Unique Locations",
                    value: "\(stats.uniqueLocationsVisited)",
                    progress: Double(stats.uniqueLocationsVisited) / 50.0,
                    color: .green
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct DifficultyChartSection: View {
    let stats: GameStatistics
    
    var chartData: [DifficultyData] {
        stats.treasuresByDifficulty.map { DifficultyData(difficulty: $0.key, count: $0.value) }
            .sorted { $0.difficulty < $1.difficulty }
    }
    
    struct DifficultyData: Identifiable {
        let id = UUID()
        let difficulty: Int
        let count: Int
        
        var difficultyLabel: String {
            switch difficulty {
            case 1: return "Easy"
            case 2: return "Medium"
            case 3: return "Hard"
            default: return "Level \(difficulty)"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Treasures by Difficulty")
                .font(.headline)
            
            if !chartData.isEmpty {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Difficulty", item.difficultyLabel),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct AchievementsSection: View {
    let stats: GameStatistics
    
    let achievements = [
        ("first_treasure", "First Treasure", "star.fill"),
        ("collector_10", "10 Treasures", "star.circle.fill"),
        ("collector_50", "50 Treasures", "star.square.fill"),
        ("master_collector", "100 Treasures", "crown.fill"),
        ("creator_5", "Creator", "paintbrush.fill"),
        ("week_streak", "Week Streak", "flame.fill"),
        ("month_streak", "Month Streak", "flame.circle.fill"),
        ("explorer_10km", "Explorer", "location.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(achievements, id: \.0) { achievement in
                    let isUnlocked = stats.achievementIds.contains(achievement.0)
                    
                    VStack {
                        Image(systemName: achievement.2)
                            .font(.title2)
                            .foregroundColor(isUnlocked ? .yellow : .gray)
                        
                        Text(achievement.1)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isUnlocked ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isUnlocked ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct ActivitySection: View {
    let stats: GameStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if let firstDate = stats.firstTreasureDate {
                    HStack {
                        Text("First Treasure:")
                        Spacer()
                        Text(firstDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let recentDate = stats.mostRecentTreasureDate {
                    HStack {
                        Text("Most Recent:")
                        Spacer()
                        Text(recentDate, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Last Played:")
                    Spacer()
                    Text(stats.lastPlayedDate, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressRow: View {
    let label: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .tint(color)
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(PersistenceManager.shared)
}