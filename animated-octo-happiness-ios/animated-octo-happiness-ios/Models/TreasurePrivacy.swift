//
//  TreasurePrivacy.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation

enum PrivacyLevel: String, Codable, CaseIterable {
    case publicAccess = "public"
    case friendsOnly = "friends"
    case groupOnly = "group"
    case privateAccess = "private"
    
    var displayName: String {
        switch self {
        case .publicAccess: return "Public"
        case .friendsOnly: return "Friends Only"
        case .groupOnly: return "Group Only"
        case .privateAccess: return "Private"
        }
    }
    
    var icon: String {
        switch self {
        case .publicAccess: return "globe"
        case .friendsOnly: return "person.2"
        case .groupOnly: return "person.3"
        case .privateAccess: return "lock"
        }
    }
    
    var description: String {
        switch self {
        case .publicAccess: return "Anyone can see and find this treasure"
        case .friendsOnly: return "Only your friends can see this treasure"
        case .groupOnly: return "Only group members can see this treasure"
        case .privateAccess: return "Only you can see this treasure"
        }
    }
}