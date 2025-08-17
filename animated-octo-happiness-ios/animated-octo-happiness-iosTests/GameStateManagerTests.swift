//
//  GameStateManagerTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Alex on 8/17/25.
//

import XCTest
@testable import animated_octo_happiness_ios

class GameStateManagerTests: XCTestCase {
    var gameStateManager: GameStateManager!
    
    override func setUp() {
        super.setUp()
        gameStateManager = GameStateManager()
        gameStateManager.resetProgress()
    }
    
    override func tearDown() {
        gameStateManager.resetProgress()
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(gameStateManager.playerStats.totalTreasuresFound, 0)
        XCTAssertEqual(gameStateManager.playerStats.totalScore, 0)
        XCTAssertTrue(gameStateManager.discoveredTreasures.isEmpty)
        XCTAssertFalse(gameStateManager.achievements.isEmpty)
    }
    
    func testRecordTreasureDiscovery() {
        let treasure = Treasure(type: .gold, position: [0, 0, 0])
        gameStateManager.recordTreasureDiscovery(treasure)
        
        XCTAssertEqual(gameStateManager.playerStats.totalTreasuresFound, 1)
        XCTAssertEqual(gameStateManager.playerStats.totalScore, 100)
        XCTAssertEqual(gameStateManager.playerStats.goldTreasuresFound, 1)
        XCTAssertTrue(gameStateManager.discoveredTreasures.contains(treasure.id))
    }
    
    func testAchievementUnlocking() {
        let treasure = Treasure(type: .gold, position: [0, 0, 0])
        gameStateManager.recordTreasureDiscovery(treasure)
        
        let firstTreasureAchievement = gameStateManager.achievements.first { $0.id == "first_treasure" }
        XCTAssertNotNil(firstTreasureAchievement)
        XCTAssertTrue(firstTreasureAchievement!.isUnlocked)
    }
    
    func testSessionComplete() {
        gameStateManager.recordSessionComplete(treasuresFound: 10, totalTreasures: 10)
        
        XCTAssertEqual(gameStateManager.playerStats.sessionsPlayed, 1)
        XCTAssertEqual(gameStateManager.playerStats.perfectSessions, 1)
    }
    
    func testPlayTimeUpdate() {
        gameStateManager.updatePlayTime(15)
        XCTAssertEqual(gameStateManager.playerStats.totalPlayTimeMinutes, 15)
        
        gameStateManager.updatePlayTime(20)
        XCTAssertEqual(gameStateManager.playerStats.totalPlayTimeMinutes, 35)
    }
    
    func testResetProgress() {
        let treasure = Treasure(type: .gold, position: [0, 0, 0])
        gameStateManager.recordTreasureDiscovery(treasure)
        gameStateManager.resetProgress()
        
        XCTAssertEqual(gameStateManager.playerStats.totalTreasuresFound, 0)
        XCTAssertEqual(gameStateManager.playerStats.totalScore, 0)
        XCTAssertTrue(gameStateManager.discoveredTreasures.isEmpty)
        
        let achievements = gameStateManager.achievements
        XCTAssertTrue(achievements.allSatisfy { !$0.isUnlocked })
    }
}