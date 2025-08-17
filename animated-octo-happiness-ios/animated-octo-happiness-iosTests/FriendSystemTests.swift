//
//  FriendSystemTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

class FriendSystemTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var friendService: FriendService!
    var groupService: GroupService!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([
            User.self,
            FriendRequest.self,
            TreasureGroup.self,
            ActivityFeedItem.self,
            Treasure.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
            friendService = FriendService(modelContext: modelContext)
            groupService = GroupService(modelContext: modelContext, friendService: friendService)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        friendService = nil
        groupService = nil
        super.tearDown()
    }
    
    func testUserCreation() {
        let user = User(
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com",
            avatarEmoji: "🎮"
        )
        
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.avatarEmoji, "🎮")
        XCTAssertFalse(user.isBlocked)
        XCTAssertTrue(user.friends.isEmpty)
        XCTAssertTrue(user.blockedUsers.isEmpty)
    }
    
    func testFriendRequest() {
        let user1 = User(username: "user1", displayName: "User 1")
        let user2 = User(username: "user2", displayName: "User 2")
        
        let request = FriendRequest(from: user1, to: user2, message: "Let's be friends!")
        
        XCTAssertEqual(request.status, .pending)
        XCTAssertEqual(request.fromUser?.username, "user1")
        XCTAssertEqual(request.toUser?.username, "user2")
        XCTAssertEqual(request.message, "Let's be friends!")
        XCTAssertNil(request.respondedAt)
    }
    
    func testAcceptFriendRequest() {
        let user1 = User(username: "user1", displayName: "User 1")
        let user2 = User(username: "user2", displayName: "User 2")
        
        modelContext.insert(user1)
        modelContext.insert(user2)
        
        let request = FriendRequest(from: user1, to: user2)
        modelContext.insert(request)
        
        request.accept()
        
        XCTAssertEqual(request.status, .accepted)
        XCTAssertNotNil(request.respondedAt)
        XCTAssertTrue(user1.isFriend(with: user2))
        XCTAssertTrue(user2.isFriend(with: user1))
    }
    
    func testDeclineFriendRequest() {
        let user1 = User(username: "user1", displayName: "User 1")
        let user2 = User(username: "user2", displayName: "User 2")
        
        let request = FriendRequest(from: user1, to: user2)
        request.decline()
        
        XCTAssertEqual(request.status, .declined)
        XCTAssertNotNil(request.respondedAt)
        XCTAssertFalse(user1.isFriend(with: user2))
        XCTAssertFalse(user2.isFriend(with: user1))
    }
    
    func testBlockUser() {
        let user1 = User(username: "user1", displayName: "User 1")
        let user2 = User(username: "user2", displayName: "User 2")
        
        user1.friends.append(user2)
        user2.friends.append(user1)
        
        XCTAssertTrue(user1.isFriend(with: user2))
        
        user1.blockUser(user2)
        
        XCTAssertTrue(user1.hasBlockedUser(user2))
        XCTAssertFalse(user1.isFriend(with: user2))
    }
    
    func testUnblockUser() {
        let user1 = User(username: "user1", displayName: "User 1")
        let user2 = User(username: "user2", displayName: "User 2")
        
        user1.blockUser(user2)
        XCTAssertTrue(user1.hasBlockedUser(user2))
        
        user1.unblockUser(user2)
        XCTAssertFalse(user1.hasBlockedUser(user2))
    }
    
    func testTreasureGroupCreation() {
        let owner = User(username: "owner", displayName: "Group Owner")
        let group = TreasureGroup(
            name: "Treasure Hunters",
            description: "A group for treasure hunters",
            owner: owner,
            emoji: "🏴‍☠️"
        )
        
        XCTAssertEqual(group.name, "Treasure Hunters")
        XCTAssertEqual(group.groupDescription, "A group for treasure hunters")
        XCTAssertEqual(group.emoji, "🏴‍☠️")
        XCTAssertTrue(group.isActive)
        XCTAssertTrue(group.isMember(owner))
        XCTAssertTrue(group.isOwner(owner))
        XCTAssertEqual(group.members.count, 1)
    }
    
    func testAddMemberToGroup() {
        let owner = User(username: "owner", displayName: "Group Owner")
        let member = User(username: "member", displayName: "Group Member")
        let group = TreasureGroup(name: "Test Group", owner: owner)
        
        group.addMember(member)
        
        XCTAssertEqual(group.members.count, 2)
        XCTAssertTrue(group.isMember(member))
        XCTAssertFalse(group.isOwner(member))
    }
    
    func testRemoveMemberFromGroup() {
        let owner = User(username: "owner", displayName: "Group Owner")
        let member = User(username: "member", displayName: "Group Member")
        let group = TreasureGroup(name: "Test Group", owner: owner)
        
        group.addMember(member)
        XCTAssertEqual(group.members.count, 2)
        
        group.removeMember(member)
        XCTAssertEqual(group.members.count, 1)
        XCTAssertFalse(group.isMember(member))
    }
    
    func testTreasurePrivacy() {
        let owner = User(username: "owner", displayName: "Owner")
        let friend = User(username: "friend", displayName: "Friend")
        let stranger = User(username: "stranger", displayName: "Stranger")
        
        owner.friends.append(friend)
        friend.friends.append(owner)
        
        let publicTreasure = Treasure(
            title: "Public Treasure",
            description: "Everyone can see this",
            latitude: 0,
            longitude: 0,
            privacy: .public,
            owner: owner
        )
        
        let privateTreasure = Treasure(
            title: "Private Treasure",
            description: "Only owner can see this",
            latitude: 0,
            longitude: 0,
            privacy: .private,
            owner: owner
        )
        
        let friendsTreasure = Treasure(
            title: "Friends Treasure",
            description: "Only friends can see this",
            latitude: 0,
            longitude: 0,
            privacy: .friends,
            owner: owner
        )
        
        XCTAssertTrue(publicTreasure.canBeSeenBy(user: owner))
        XCTAssertTrue(publicTreasure.canBeSeenBy(user: friend))
        XCTAssertTrue(publicTreasure.canBeSeenBy(user: stranger))
        
        XCTAssertTrue(privateTreasure.canBeSeenBy(user: owner))
        XCTAssertFalse(privateTreasure.canBeSeenBy(user: friend))
        XCTAssertFalse(privateTreasure.canBeSeenBy(user: stranger))
        
        XCTAssertTrue(friendsTreasure.canBeSeenBy(user: owner))
        XCTAssertTrue(friendsTreasure.canBeSeenBy(user: friend))
        XCTAssertFalse(friendsTreasure.canBeSeenBy(user: stranger))
    }
    
    func testTreasureSharing() {
        let owner = User(username: "owner", displayName: "Owner")
        let user = User(username: "user", displayName: "User")
        let group = TreasureGroup(name: "Test Group", owner: owner)
        
        let treasure = Treasure(
            title: "Shared Treasure",
            description: "This will be shared",
            latitude: 0,
            longitude: 0,
            owner: owner
        )
        
        treasure.shareWith(user: user)
        XCTAssertTrue(treasure.sharedWithUsers.contains { $0.id == user.id })
        
        treasure.shareWith(group: group)
        XCTAssertTrue(treasure.sharedWithGroups.contains { $0.id == group.id })
        XCTAssertTrue(group.sharedTreasures.contains { $0.id == treasure.id })
    }
    
    func testActivityFeedItemCreation() {
        let user = User(username: "user", displayName: "User")
        let treasure = Treasure(
            title: "Test Treasure",
            description: "Test",
            latitude: 0,
            longitude: 0
        )
        
        let activity = ActivityFeedItem.treasureCollected(by: user, treasure: treasure)
        
        XCTAssertEqual(activity.type, .treasureCollected)
        XCTAssertEqual(activity.title, "User found a treasure!")
        XCTAssertEqual(activity.message, "User collected Test Treasure")
        XCTAssertFalse(activity.isRead)
        
        activity.markAsRead()
        XCTAssertTrue(activity.isRead)
    }
}

class FriendServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var friendService: FriendService!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([
            User.self,
            FriendRequest.self,
            TreasureGroup.self,
            ActivityFeedItem.self,
            Treasure.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
            friendService = FriendService(modelContext: modelContext)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    func testLoadCurrentUser() {
        friendService.loadCurrentUser()
        XCTAssertNotNil(friendService.currentUser)
        XCTAssertEqual(friendService.currentUser?.username, "currentUser")
    }
    
    func testSendFriendRequest() throws {
        friendService.loadCurrentUser()
        
        let targetUser = User(username: "targetUser", displayName: "Target User")
        modelContext.insert(targetUser)
        try modelContext.save()
        
        try friendService.sendFriendRequest(to: "targetUser", message: "Hello!")
        
        XCTAssertFalse(friendService.friendRequests.isEmpty)
    }
}