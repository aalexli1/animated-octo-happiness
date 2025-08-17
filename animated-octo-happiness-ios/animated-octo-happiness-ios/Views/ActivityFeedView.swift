//
//  ActivityFeedView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct ActivityFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityFeedItem.timestamp, order: .reverse) private var activities: [ActivityFeedItem]
    @State private var selectedFilter: ActivityType?
    @State private var showingFilters = false
    
    private var filteredActivities: [ActivityFeedItem] {
        if let filter = selectedFilter {
            return activities.filter { $0.type == filter }
        }
        return activities
    }
    
    private var unreadCount: Int {
        activities.filter { !$0.isRead }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !filteredActivities.isEmpty {
                    ForEach(groupedActivities, id: \.key) { day, dayActivities in
                        Section(header: Text(dayHeader(for: day))) {
                            ForEach(dayActivities) { activity in
                                ActivityRowView(activity: activity)
                                    .onAppear {
                                        if !activity.isRead {
                                            activity.markAsRead()
                                            try? modelContext.save()
                                        }
                                    }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        selectedFilter != nil ? "No \(selectedFilter!.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) Activities" : "No Activity Yet",
                        systemImage: "bell",
                        description: Text(selectedFilter != nil ? "No activities of this type" : "Your friends' activities will appear here")
                    )
                }
            }
            .navigationTitle("Activity Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: selectedFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                
                if unreadCount > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: markAllAsRead) {
                            Text("Mark All Read")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedFilter: $selectedFilter)
            }
        }
    }
    
    private var groupedActivities: [(key: Date, value: [ActivityFeedItem])] {
        let grouped = Dictionary(grouping: filteredActivities) { activity in
            Calendar.current.startOfDay(for: activity.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func dayHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func markAllAsRead() {
        for activity in activities where !activity.isRead {
            activity.markAsRead()
        }
        try? modelContext.save()
    }
}

struct ActivityRowView: View {
    let activity: ActivityFeedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(activity.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(backgroundColor(for: activity.type))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundColor(!activity.isRead ? .primary : .secondary)
                
                Text(activity.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(activity.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !activity.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Spacer()
            
            if let relatedUser = activity.relatedUser {
                Text(relatedUser.avatarEmoji)
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
    }
    
    private func backgroundColor(for type: ActivityType) -> Color {
        switch type {
        case .treasureCreated, .treasureFound:
            return .green.opacity(0.2)
        case .treasureShared:
            return .orange.opacity(0.2)
        case .friendRequestSent, .friendRequestAccepted:
            return .blue.opacity(0.2)
        case .groupCreated, .groupJoined:
            return .purple.opacity(0.2)
        case .achievementUnlocked:
            return .yellow.opacity(0.2)
        }
    }
}

struct FilterView: View {
    @Binding var selectedFilter: ActivityType?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        selectedFilter = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("All Activities")
                            Spacer()
                            if selectedFilter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Filter by Type") {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedFilter = type
                            dismiss()
                        }) {
                            HStack {
                                Text(activityEmoji(for: type))
                                    .frame(width: 30)
                                Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                Spacer()
                                if selectedFilter == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func activityEmoji(for type: ActivityType) -> String {
        switch type {
        case .treasureCreated: return "✨"
        case .treasureFound: return "🎉"
        case .treasureShared: return "🤝"
        case .friendRequestSent: return "👋"
        case .friendRequestAccepted: return "✅"
        case .groupCreated: return "👥"
        case .groupJoined: return "🤝"
        case .achievementUnlocked: return "🏆"
        }
    }
}

#Preview {
    ActivityFeedView()
        .modelContainer(for: [ActivityFeedItem.self, User.self, Treasure.self, HuntingGroup.self])
}