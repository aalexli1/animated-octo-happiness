//
//  GroupService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class GroupService: ObservableObject {
    @Published var myGroups: [HuntingGroup] = []
    @Published var joinedGroups: [HuntingGroup] = []
    
    private var modelContext: ModelContext?
    private var currentUser: User?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setCurrentUser(_ user: User) {
        self.currentUser = user
        Task {
            await refreshGroups()
        }
    }
    
    func createGroup(name: String, description: String?, emoji: String, maxMembers: Int = 20) async throws -> HuntingGroup {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        let group = HuntingGroup(
            name: name,
            description: description,
            emoji: emoji,
            owner: currentUser,
            maxMembers: maxMembers
        )
        
        modelContext.insert(group)
        
        let activity = ActivityFeedItem(
            type: .groupCreated,
            title: "Group Created",
            message: "You created the group '\(name)'",
            user: currentUser,
            relatedGroup: group
        )
        modelContext.insert(activity)
        
        try modelContext.save()
        await refreshGroups()
        
        return group
    }
    
    func joinGroup(withCode code: String) async throws -> HuntingGroup {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        let descriptor = FetchDescriptor<HuntingGroup>(
            predicate: #Predicate { group in
                group.inviteCode == code && group.isActive
            }
        )
        
        guard let group = try modelContext.fetch(descriptor).first else {
            throw GroupServiceError.invalidInviteCode
        }
        
        guard !group.isFull else {
            throw GroupServiceError.groupFull
        }
        
        guard !group.isMember(currentUser) else {
            throw GroupServiceError.alreadyMember
        }
        
        let success = group.addMember(currentUser)
        guard success else {
            throw GroupServiceError.joinFailed
        }
        
        let activity = ActivityFeedItem(
            type: .groupJoined,
            title: "Joined Group",
            message: "You joined the group '\(group.name)'",
            user: currentUser,
            relatedGroup: group
        )
        modelContext.insert(activity)
        
        if let owner = group.owner {
            let ownerActivity = ActivityFeedItem(
                type: .groupJoined,
                title: "New Member",
                message: "\(currentUser.displayName) joined your group '\(group.name)'",
                user: owner,
                relatedUser: currentUser,
                relatedGroup: group
            )
            modelContext.insert(ownerActivity)
        }
        
        try modelContext.save()
        await refreshGroups()
        
        return group
    }
    
    func leaveGroup(_ group: HuntingGroup) async throws {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        guard group.isMember(currentUser) else {
            throw GroupServiceError.notMember
        }
        
        guard !group.isOwner(currentUser) else {
            throw GroupServiceError.ownerCannotLeave
        }
        
        group.removeMember(currentUser)
        try modelContext.save()
        await refreshGroups()
    }
    
    func deleteGroup(_ group: HuntingGroup) async throws {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        guard group.isOwner(currentUser) else {
            throw GroupServiceError.notOwner
        }
        
        modelContext.delete(group)
        try modelContext.save()
        await refreshGroups()
    }
    
    func regenerateInviteCode(for group: HuntingGroup) async throws {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        guard group.isOwner(currentUser) else {
            throw GroupServiceError.notOwner
        }
        
        group.regenerateInviteCode()
        try modelContext.save()
    }
    
    func removeMember(_ member: User, from group: HuntingGroup) async throws {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        guard group.isOwner(currentUser) else {
            throw GroupServiceError.notOwner
        }
        
        guard member.id != currentUser.id else {
            throw GroupServiceError.cannotRemoveSelf
        }
        
        group.removeMember(member)
        try modelContext.save()
        await refreshGroups()
    }
    
    func shareWithGroup(_ treasure: Treasure, group: HuntingGroup) async throws {
        guard let currentUser = currentUser else {
            throw GroupServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw GroupServiceError.contextNotSet
        }
        
        guard treasure.owner?.id == currentUser.id else {
            throw GroupServiceError.notTreasureOwner
        }
        
        guard group.isMember(currentUser) else {
            throw GroupServiceError.notMember
        }
        
        treasure.shareWithGroup(group)
        
        if group.sharedTreasures == nil {
            group.sharedTreasures = []
        }
        group.sharedTreasures?.append(treasure)
        
        for member in group.members ?? [] {
            if member.id != currentUser.id {
                let activity = ActivityFeedItem(
                    type: .treasureShared,
                    title: "New Treasure Shared",
                    message: "\(currentUser.displayName) shared '\(treasure.title)' with the group",
                    user: member,
                    relatedUser: currentUser,
                    relatedTreasure: treasure,
                    relatedGroup: group
                )
                modelContext.insert(activity)
            }
        }
        
        try modelContext.save()
    }
    
    private func refreshGroups() async {
        guard let currentUser = currentUser,
              let modelContext = modelContext else { return }
        
        do {
            let ownedDescriptor = FetchDescriptor<HuntingGroup>(
                predicate: #Predicate { group in
                    group.owner?.id == currentUser.id && group.isActive
                }
            )
            self.myGroups = try modelContext.fetch(ownedDescriptor)
            
            let joinedDescriptor = FetchDescriptor<HuntingGroup>(
                predicate: #Predicate { group in
                    group.members != nil &&
                    group.isActive
                }
            )
            let allGroups = try modelContext.fetch(joinedDescriptor)
            self.joinedGroups = allGroups.filter { group in
                group.isMember(currentUser) && !group.isOwner(currentUser)
            }
        } catch {
            print("Error refreshing groups: \(error)")
        }
    }
}

enum GroupServiceError: LocalizedError {
    case notAuthenticated
    case contextNotSet
    case invalidInviteCode
    case groupFull
    case alreadyMember
    case joinFailed
    case notMember
    case notOwner
    case ownerCannotLeave
    case cannotRemoveSelf
    case notTreasureOwner
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .contextNotSet:
            return "Database context not initialized"
        case .invalidInviteCode:
            return "Invalid or expired invite code"
        case .groupFull:
            return "This group is full"
        case .alreadyMember:
            return "You are already a member of this group"
        case .joinFailed:
            return "Failed to join the group"
        case .notMember:
            return "You are not a member of this group"
        case .notOwner:
            return "Only the group owner can perform this action"
        case .ownerCannotLeave:
            return "Group owner cannot leave. Delete the group instead."
        case .cannotRemoveSelf:
            return "You cannot remove yourself from the group"
        case .notTreasureOwner:
            return "You can only share your own treasures"
        }
    }
}