//
//  FriendSystemTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

@MainActor
final class FriendSystemTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var friendService: FriendService!
    var user1: User!
    var user2: User!
    var user3: User!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: User.self, FriendRelationship.self, FriendRequest.self,
            HuntingGroup.self, Treasure.self, ActivityFeedItem.self,
            configurations: config
        )
        context = ModelContext(container)
        
        friendService = FriendService()
        friendService.setModelContext(context)
        
        user1 = User(username: "user1", displayName: "User One", avatarEmoji: "🧑")
        user2 = User(username: "user2", displayName: "User Two", avatarEmoji: "👤")
        user3 = User(username: "user3", displayName: "User Three", avatarEmoji: "👥")
        
        context.insert(user1)
        context.insert(user2)
        context.insert(user3)
        try context.save()
        
        friendService.currentUser = user1
    }
    
    override func tearDown() async throws {
        friendService = nil
        user1 = nil
        user2 = nil
        user3 = nil
        context = nil
        container = nil
        try await super.tearDown()
    }
    
    func testSendFriendRequest() async throws {
        try await friendService.sendFriendRequest(to: user2, message: "Let's be friends!")
        
        let descriptor = FetchDescriptor<FriendRequest>()
        let requests = try context.fetch(descriptor)
        
        XCTAssertEqual(requests.count, 1)
        let request = requests[0]
        XCTAssertEqual(request.sender?.id, user1.id)
        XCTAssertEqual(request.receiver?.id, user2.id)
        XCTAssertEqual(request.message, "Let's be friends!")
        XCTAssertEqual(request.status, .pending)
    }
    
    func testAcceptFriendRequest() async throws {
        let request = FriendRequest(sender: user2, receiver: user1)
        context.insert(request)
        try context.save()
        
        friendService.currentUser = user1
        try await friendService.acceptFriendRequest(request)
        
        XCTAssertEqual(request.status, .accepted)
        XCTAssertNotNil(request.respondedAt)
        
        let descriptor = FetchDescriptor<FriendRelationship>()
        let relationships = try context.fetch(descriptor)
        XCTAssertEqual(relationships.count, 2)
        
        let relationship1 = relationships.first { $0.user?.id == user1.id }
        XCTAssertNotNil(relationship1)
        XCTAssertEqual(relationship1?.friend?.id, user2.id)
        XCTAssertEqual(relationship1?.status, .accepted)
        
        let relationship2 = relationships.first { $0.user?.id == user2.id }
        XCTAssertNotNil(relationship2)
        XCTAssertEqual(relationship2?.friend?.id, user1.id)
        XCTAssertEqual(relationship2?.status, .accepted)
    }
    
    func testDeclineFriendRequest() async throws {
        let request = FriendRequest(sender: user2, receiver: user1)
        context.insert(request)
        try context.save()
        
        friendService.currentUser = user1
        try await friendService.declineFriendRequest(request)
        
        XCTAssertEqual(request.status, .declined)
        XCTAssertNotNil(request.respondedAt)
        
        let descriptor = FetchDescriptor<FriendRelationship>()
        let relationships = try context.fetch(descriptor)
        XCTAssertEqual(relationships.count, 0)
    }
    
    func testBlockUser() async throws {
        try await friendService.blockUser(user2)
        
        let descriptor = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate<FriendRelationship> { relationship in
                relationship.status == .blocked
            }
        )
        let relationships = try context.fetch(descriptor)
        
        XCTAssertEqual(relationships.count, 1)
        let relationship = relationships[0]
        XCTAssertEqual(relationship.user?.id, user1.id)
        XCTAssertEqual(relationship.friend?.id, user2.id)
        XCTAssertEqual(relationship.status, .blocked)
    }
    
    func testUserIsFriendWith() async throws {
        let friendship1 = FriendRelationship(user: user1, friend: user2, status: .accepted)
        let friendship2 = FriendRelationship(user: user2, friend: user1, status: .accepted)
        user1.friendships = [friendship1]
        user2.friendships = [friendship2]
        
        context.insert(friendship1)
        context.insert(friendship2)
        try context.save()
        
        XCTAssertTrue(user1.isFriendWith(user2))
        XCTAssertTrue(user2.isFriendWith(user1))
        XCTAssertFalse(user1.isFriendWith(user3))
    }
    
    func testSearchUsers() async throws {
        let results = try await friendService.searchUsers(query: "User")
        XCTAssertEqual(results.count, 3)
        
        let results2 = try await friendService.searchUsers(query: "Two")
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results2[0].username, "user2")
    }
}

@MainActor
final class GroupServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var groupService: GroupService!
    var user1: User!
    var user2: User!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: User.self, HuntingGroup.self, Treasure.self, ActivityFeedItem.self,
            configurations: config
        )
        context = ModelContext(container)
        
        groupService = GroupService()
        groupService.setModelContext(context)
        
        user1 = User(username: "user1", displayName: "User One")
        user2 = User(username: "user2", displayName: "User Two")
        
        context.insert(user1)
        context.insert(user2)
        try context.save()
        
        groupService.setCurrentUser(user1)
    }
    
    override func tearDown() async throws {
        groupService = nil
        user1 = nil
        user2 = nil
        context = nil
        container = nil
        try await super.tearDown()
    }
    
    func testCreateGroup() async throws {
        let group = try await groupService.createGroup(
            name: "Test Group",
            description: "A test group",
            emoji: "🎯",
            maxMembers: 10
        )
        
        XCTAssertEqual(group.name, "Test Group")
        XCTAssertEqual(group.groupDescription, "A test group")
        XCTAssertEqual(group.emoji, "🎯")
        XCTAssertEqual(group.maxMembers, 10)
        XCTAssertEqual(group.owner?.id, user1.id)
        XCTAssertTrue(group.isMember(user1))
        XCTAssertEqual(group.memberCount, 1)
    }
    
    func testJoinGroupWithCode() async throws {
        let group = HuntingGroup(
            name: "Existing Group",
            description: nil,
            emoji: "👥",
            owner: user2
        )
        context.insert(group)
        try context.save()
        
        let joinedGroup = try await groupService.joinGroup(withCode: group.inviteCode)
        
        XCTAssertEqual(joinedGroup.id, group.id)
        XCTAssertTrue(group.isMember(user1))
        XCTAssertEqual(group.memberCount, 2)
    }
    
    func testLeaveGroup() async throws {
        let group = HuntingGroup(
            name: "Test Group",
            owner: user2
        )
        group.addMember(user1)
        context.insert(group)
        try context.save()
        
        XCTAssertTrue(group.isMember(user1))
        
        try await groupService.leaveGroup(group)
        
        XCTAssertFalse(group.isMember(user1))
    }
    
    func testGroupInviteCodeGeneration() {
        let group = HuntingGroup(
            name: "Test Group",
            owner: user1
        )
        
        XCTAssertEqual(group.inviteCode.count, 6)
        XCTAssertTrue(group.inviteCode.allSatisfy { $0.isLetter || $0.isNumber })
        
        let oldCode = group.inviteCode
        group.regenerateInviteCode()
        
        XCTAssertNotEqual(group.inviteCode, oldCode)
        XCTAssertEqual(group.inviteCode.count, 6)
    }
    
    func testGroupMemberManagement() {
        let group = HuntingGroup(
            name: "Test Group",
            owner: user1,
            maxMembers: 3
        )
        
        XCTAssertEqual(group.memberCount, 1)
        XCTAssertFalse(group.isFull)
        
        XCTAssertTrue(group.addMember(user2))
        XCTAssertEqual(group.memberCount, 2)
        XCTAssertTrue(group.isMember(user2))
        
        XCTAssertFalse(group.addMember(user2))
        
        group.removeMember(user2)
        XCTAssertEqual(group.memberCount, 1)
        XCTAssertFalse(group.isMember(user2))
    }
}

@MainActor
final class TreasurePrivacyTests: XCTestCase {
    var user1: User!
    var user2: User!
    var user3: User!
    var group: HuntingGroup!
    var treasure: Treasure!
    
    override func setUp() async throws {
        try await super.setUp()
        
        user1 = User(username: "owner", displayName: "Owner")
        user2 = User(username: "friend", displayName: "Friend")
        user3 = User(username: "stranger", displayName: "Stranger")
        
        let friendship = FriendRelationship(user: user1, friend: user2, status: .accepted)
        user1.friendships = [friendship]
        
        group = HuntingGroup(name: "Test Group", owner: user1)
        group.addMember(user1)
        group.addMember(user2)
        
        treasure = Treasure(
            title: "Test Treasure",
            description: "A test treasure",
            latitude: 0,
            longitude: 0,
            owner: user1
        )
    }
    
    func testPublicTreasureVisibility() {
        treasure.privacyLevel = .publicAccess
        
        XCTAssertTrue(treasure.canBeViewedBy(user1))
        XCTAssertTrue(treasure.canBeViewedBy(user2))
        XCTAssertTrue(treasure.canBeViewedBy(user3))
        XCTAssertTrue(treasure.canBeViewedBy(nil))
    }
    
    func testPrivateTreasureVisibility() {
        treasure.privacyLevel = .privateAccess
        
        XCTAssertTrue(treasure.canBeViewedBy(user1))
        XCTAssertFalse(treasure.canBeViewedBy(user2))
        XCTAssertFalse(treasure.canBeViewedBy(user3))
        XCTAssertFalse(treasure.canBeViewedBy(nil))
    }
    
    func testFriendsOnlyTreasureVisibility() {
        treasure.privacyLevel = .friendsOnly
        
        XCTAssertTrue(treasure.canBeViewedBy(user1))
        XCTAssertTrue(treasure.canBeViewedBy(user2))
        XCTAssertFalse(treasure.canBeViewedBy(user3))
        XCTAssertFalse(treasure.canBeViewedBy(nil))
    }
    
    func testGroupOnlyTreasureVisibility() {
        treasure.privacyLevel = .groupOnly
        treasure.sharedWithGroup = group
        
        XCTAssertTrue(treasure.canBeViewedBy(user1))
        XCTAssertTrue(treasure.canBeViewedBy(user2))
        XCTAssertFalse(treasure.canBeViewedBy(user3))
        XCTAssertFalse(treasure.canBeViewedBy(nil))
    }
    
    func testTreasureSharing() {
        XCTAssertNil(treasure.sharedWithUsers)
        
        treasure.shareWith(users: [user2, user3])
        
        XCTAssertNotNil(treasure.sharedWithUsers)
        XCTAssertEqual(treasure.sharedWithUsers?.count, 2)
        XCTAssertTrue(treasure.sharedWithUsers?.contains { $0.id == user2.id } ?? false)
        XCTAssertTrue(treasure.sharedWithUsers?.contains { $0.id == user3.id } ?? false)
        
        treasure.shareWith(users: [user2])
        XCTAssertEqual(treasure.sharedWithUsers?.count, 2)
        
        treasure.removeSharing(for: user2)
        XCTAssertEqual(treasure.sharedWithUsers?.count, 1)
        XCTAssertFalse(treasure.sharedWithUsers?.contains { $0.id == user2.id } ?? false)
    }
}

@MainActor
final class ActivityFeedTests: XCTestCase {
    var user1: User!
    var user2: User!
    var treasure: Treasure!
    var group: HuntingGroup!
    
    override func setUp() async throws {
        try await super.setUp()
        
        user1 = User(username: "user1", displayName: "User One")
        user2 = User(username: "user2", displayName: "User Two")
        treasure = Treasure(
            title: "Test Treasure",
            description: "Test",
            latitude: 0,
            longitude: 0
        )
        group = HuntingGroup(name: "Test Group", owner: user1)
    }
    
    func testActivityFeedItemCreation() {
        let activity = ActivityFeedItem(
            type: .treasureFound,
            title: "Treasure Found!",
            message: "You found a treasure",
            user: user1,
            relatedUser: user2,
            relatedTreasure: treasure,
            relatedGroup: group
        )
        
        XCTAssertEqual(activity.type, .treasureFound)
        XCTAssertEqual(activity.title, "Treasure Found!")
        XCTAssertEqual(activity.message, "You found a treasure")
        XCTAssertEqual(activity.user?.id, user1.id)
        XCTAssertEqual(activity.relatedUser?.id, user2.id)
        XCTAssertEqual(activity.relatedTreasure?.id, treasure.id)
        XCTAssertEqual(activity.relatedGroup?.id, group.id)
        XCTAssertFalse(activity.isRead)
    }
    
    func testActivityFeedItemMarkAsRead() {
        let activity = ActivityFeedItem(
            type: .friendRequestAccepted,
            title: "Friend Request Accepted",
            message: "Your request was accepted",
            user: user1
        )
        
        XCTAssertFalse(activity.isRead)
        
        activity.markAsRead()
        
        XCTAssertTrue(activity.isRead)
    }
    
    func testActivityEmojis() {
        let activities: [(ActivityType, String)] = [
            (.treasureCreated, "✨"),
            (.treasureFound, "🎉"),
            (.treasureShared, "🤝"),
            (.friendRequestSent, "👋"),
            (.friendRequestAccepted, "✅"),
            (.groupCreated, "👥"),
            (.groupJoined, "🤝"),
            (.achievementUnlocked, "🏆")
        ]
        
        for (type, expectedEmoji) in activities {
            let activity = ActivityFeedItem(
                type: type,
                title: "Test",
                message: "Test",
                user: user1
            )
            XCTAssertEqual(activity.emoji, expectedEmoji)
        }
    }
}