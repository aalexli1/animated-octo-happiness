//
//  GameStatisticsTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

final class GameStatisticsTests: XCTestCase {
    var stats: GameStatistics!
    
    override func setUp() {
        super.setUp()
        stats = GameStatistics(userId: "test-user")
    }
    
    override func tearDown() {
        stats = nil
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssertEqual(stats.userId, "test-user")
        XCTAssertEqual(stats.totalTreasuresFound, 0)
        XCTAssertEqual(stats.totalTreasuresCreated, 0)
        XCTAssertEqual(stats.totalPoints, 0)
        XCTAssertEqual(stats.totalPlayTime, 0)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.longestStreak, 0)
        XCTAssertEqual(stats.distanceTraveled, 0)
        XCTAssertTrue(stats.achievementIds.isEmpty)
    }
    
    func testRecordTreasureFound() {
        let treasure = Treasure(
            title: "Test",
            description: "Test",
            latitude: 0,
            longitude: 0,
            difficulty: 2
        )
        
        stats.recordTreasureFound(treasure: treasure, points: 10)
        
        XCTAssertEqual(stats.totalTreasuresFound, 1)
        XCTAssertEqual(stats.totalPoints, 20)
        XCTAssertEqual(stats.treasuresByDifficulty[2], 1)
        XCTAssertNotNil(stats.firstTreasureDate)
        XCTAssertNotNil(stats.mostRecentTreasureDate)
        XCTAssertEqual(stats.currentStreak, 1)
    }
    
    func testRecordTreasureCreated() {
        stats.recordTreasureCreated()
        
        XCTAssertEqual(stats.totalTreasuresCreated, 1)
        XCTAssertEqual(stats.totalPoints, 5)
    }
    
    func testUpdatePlayTime() {
        let previousDate = stats.lastPlayedDate
        stats.updatePlayTime(seconds: 3600)
        
        XCTAssertEqual(stats.totalPlayTime, 3600)
        XCTAssertGreaterThan(stats.lastPlayedDate, previousDate)
    }
    
    func testUpdateDistanceTraveled() {
        stats.updateDistanceTraveled(meters: 500)
        stats.updateDistanceTraveled(meters: 750)
        
        XCTAssertEqual(stats.distanceTraveled, 1250)
    }
    
    func testFormattedPlayTime() {
        stats.totalPlayTime = 7320
        XCTAssertEqual(stats.formattedPlayTime, "2h 2m")
        
        stats.totalPlayTime = 3600
        XCTAssertEqual(stats.formattedPlayTime, "1h 0m")
        
        stats.totalPlayTime = 150
        XCTAssertEqual(stats.formattedPlayTime, "0h 2m")
    }
    
    func testFormattedDistance() {
        stats.distanceTraveled = 500
        XCTAssertEqual(stats.formattedDistance, "500 m")
        
        stats.distanceTraveled = 1500
        XCTAssertEqual(stats.formattedDistance, "1.5 km")
        
        stats.distanceTraveled = 10250
        XCTAssertEqual(stats.formattedDistance, "10.3 km")
    }
    
    func testAchievementUnlocking() {
        XCTAssertTrue(stats.achievementIds.isEmpty)
        
        let treasure = Treasure(
            title: "Test",
            description: "Test",
            latitude: 0,
            longitude: 0
        )
        
        stats.recordTreasureFound(treasure: treasure)
        let achievements = stats.checkAchievements()
        
        XCTAssertTrue(achievements.contains("first_treasure"))
        XCTAssertTrue(stats.achievementIds.contains("first_treasure"))
        
        let secondCheck = stats.checkAchievements()
        XCTAssertFalse(secondCheck.contains("first_treasure"))
    }
    
    func testMultipleAchievements() {
        for i in 0..<10 {
            let treasure = Treasure(
                title: "Test \(i)",
                description: "Test",
                latitude: 0,
                longitude: 0
            )
            stats.recordTreasureFound(treasure: treasure)
        }
        
        let achievements = stats.checkAchievements()
        XCTAssertTrue(achievements.contains("first_treasure"))
        XCTAssertTrue(achievements.contains("collector_10"))
        XCTAssertFalse(achievements.contains("collector_50"))
        
        XCTAssertEqual(stats.achievementIds.count, 2)
    }
    
    func testStreakTracking() {
        let treasure = Treasure(
            title: "Test",
            description: "Test",
            latitude: 0,
            longitude: 0
        )
        
        stats.recordTreasureFound(treasure: treasure)
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 1)
        
        stats.recordTreasureFound(treasure: treasure)
        XCTAssertEqual(stats.currentStreak, 1)
        
        stats.lastStreakDate = Date().addingTimeInterval(-86400)
        stats.recordTreasureFound(treasure: treasure)
        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(stats.longestStreak, 2)
        
        stats.lastStreakDate = Date().addingTimeInterval(-259200)
        stats.recordTreasureFound(treasure: treasure)
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 2)
    }
    
    func testDifficultyTracking() {
        let easyTreasure = Treasure(
            title: "Easy",
            description: "Test",
            latitude: 0,
            longitude: 0,
            difficulty: 1
        )
        
        let hardTreasure = Treasure(
            title: "Hard",
            description: "Test",
            latitude: 0,
            longitude: 0,
            difficulty: 3
        )
        
        stats.recordTreasureFound(treasure: easyTreasure)
        stats.recordTreasureFound(treasure: easyTreasure)
        stats.recordTreasureFound(treasure: hardTreasure)
        
        XCTAssertEqual(stats.treasuresByDifficulty[1], 2)
        XCTAssertEqual(stats.treasuresByDifficulty[3], 1)
        XCTAssertNil(stats.treasuresByDifficulty[2])
    }
}