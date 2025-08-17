//
//  GroupService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import Combine

class GroupService: ObservableObject {
    @Published var userGroups: [TreasureGroup] = []
    @Published var ownedGroups: [TreasureGroup] = []
    
    private var modelContext: ModelContext?
    private weak var friendService: FriendService?
    
    init(modelContext: ModelContext? = nil, friendService: FriendService? = nil) {
        self.modelContext = modelContext
        self.friendService = friendService
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadGroups()
    }
    
    func setFriendService(_ service: FriendService) {
        self.friendService = service
    }
    
    func loadGroups() {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else { return }
        
        let descriptor = FetchDescriptor<TreasureGroup>(
            predicate: #Predicate { group in
                group.members.contains { member in
                    member.id == currentUser.id
                }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            userGroups = try context.fetch(descriptor)
            ownedGroups = userGroups.filter { $0.owner?.id == currentUser.id }
        } catch {
            print("Error loading groups: \(error)")
        }
    }
    
    func createGroup(name: String, description: String?, emoji: String = "👥") throws -> TreasureGroup {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        let group = TreasureGroup(
            name: name,
            description: description,
            owner: currentUser,
            emoji: emoji
        )
        
        context.insert(group)
        
        let activity = ActivityFeedItem(
            type: .groupCreated,
            title: "Created a new group",
            message: "You created the group '\(name)'",
            user: currentUser,
            relatedGroup: group
        )
        context.insert(activity)
        
        try context.save()
        loadGroups()
        
        return group
    }
    
    func addMemberToGroup(_ user: User, group: TreasureGroup) throws {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        guard group.isOwner(currentUser) else {
            throw GroupServiceError.notGroupOwner
        }
        
        group.addMember(user)
        
        let activity = ActivityFeedItem(
            type: .groupJoined,
            title: "Joined a group",
            message: "You were added to '\(group.name)'",
            user: user,
            relatedGroup: group,
            relatedUser: currentUser
        )
        context.insert(activity)
        
        try context.save()
        loadGroups()
    }
    
    func removeMemberFromGroup(_ user: User, group: TreasureGroup) throws {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        guard group.isOwner(currentUser) || user.id == currentUser.id else {
            throw GroupServiceError.notGroupOwner
        }
        
        group.removeMember(user)
        try context.save()
        loadGroups()
    }
    
    func leaveGroup(_ group: TreasureGroup) throws {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        if group.isOwner(currentUser) && group.members.count > 1 {
            throw GroupServiceError.ownerCannotLeave
        }
        
        group.removeMember(currentUser)
        
        if group.members.isEmpty {
            group.isActive = false
        }
        
        try context.save()
        loadGroups()
    }
    
    func deleteGroup(_ group: TreasureGroup) throws {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        guard group.isOwner(currentUser) else {
            throw GroupServiceError.notGroupOwner
        }
        
        context.delete(group)
        try context.save()
        loadGroups()
    }
    
    func shareGroupTreasure(_ treasure: Treasure, with group: TreasureGroup) throws {
        guard let context = modelContext,
              let currentUser = friendService?.currentUser else {
            throw GroupServiceError.noCurrentUser
        }
        
        guard group.isMember(currentUser) else {
            throw GroupServiceError.notGroupMember
        }
        
        treasure.shareWith(group: group)
        
        for member in group.members where member.id != currentUser.id {
            let activity = ActivityFeedItem(
                type: .treasureShared,
                title: "Treasure shared with group",
                message: "\(currentUser.displayName) shared '\(treasure.title)' with '\(group.name)'",
                user: member,
                relatedTreasure: treasure,
                relatedUser: currentUser,
                relatedGroup: group
            )
            context.insert(activity)
        }
        
        try context.save()
    }
}

enum GroupServiceError: LocalizedError {
    case noCurrentUser
    case notGroupOwner
    case notGroupMember
    case ownerCannotLeave
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        case .notGroupOwner:
            return "You must be the group owner to perform this action"
        case .notGroupMember:
            return "You must be a group member to perform this action"
        case .ownerCannotLeave:
            return "Group owner cannot leave while other members exist"
        }
    }
}