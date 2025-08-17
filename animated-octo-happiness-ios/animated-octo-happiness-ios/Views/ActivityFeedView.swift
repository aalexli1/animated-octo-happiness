//
//  ActivityFeedView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct ActivityFeedView: View {
    @StateObject private var friendService = FriendService()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Group {
                if friendService.activityFeed.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No activity yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Friend activity will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(friendService.activityFeed, id: \.id) { item in
                            ActivityItemView(item: item)
                                .onTapGesture {
                                    item.markAsRead()
                                    try? modelContext.save()
                                }
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .onAppear {
                friendService.setModelContext(modelContext)
            }
            .refreshable {
                friendService.refreshFriendData()
            }
        }
    }
}

struct ActivityItemView: View {
    let item: ActivityFeedItem
    
    var iconName: String {
        switch item.type {
        case .treasureCreated:
            return "plus.circle.fill"
        case .treasureCollected:
            return "checkmark.circle.fill"
        case .treasureShared:
            return "square.and.arrow.up.fill"
        case .friendJoined:
            return "person.badge.plus.fill"
        case .groupCreated:
            return "person.3.fill"
        case .groupJoined:
            return "person.3.sequence.fill"
        }
    }
    
    var iconColor: Color {
        switch item.type {
        case .treasureCreated:
            return .blue
        case .treasureCollected:
            return .green
        case .treasureShared:
            return .orange
        case .friendJoined:
            return .purple
        case .groupCreated, .groupJoined:
            return .indigo
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .fontWeight(item.isRead ? .regular : .semibold)
                
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    if let relatedUser = item.relatedUser {
                        HStack(spacing: 4) {
                            Text(relatedUser.avatarEmoji)
                                .font(.caption)
                            Text(relatedUser.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let treasure = item.relatedTreasure {
                        HStack(spacing: 4) {
                            Text(treasure.emoji ?? "🎁")
                                .font(.caption)
                            Text(treasure.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(timeAgoString(from: item.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !item.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ActivityFeedView()
        .modelContainer(for: [User.self, ActivityFeedItem.self, Treasure.self], inMemory: true)
}