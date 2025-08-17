import Foundation
import SwiftData

@Model
final class NotificationPreferences {
    var achievementNotifications: Bool = true
    var treasureFoundNotifications: Bool = true
    var nearbyTreasureReminders: Bool = true
    var reminderInterval: TimeInterval = 3600
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Date()
    var quietHoursEnd: Date = Date()
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 22
        startComponents.minute = 0
        self.quietHoursStart = calendar.date(from: startComponents) ?? now
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = 8
        endComponents.minute = 0
        self.quietHoursEnd = calendar.date(from: endComponents) ?? now
    }
    
    func isWithinQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endTime = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        guard let currentMinutes = currentTime.hour.map({ $0 * 60 + (currentTime.minute ?? 0) }),
              let startMinutes = startTime.hour.map({ $0 * 60 + (startTime.minute ?? 0) }),
              let endMinutes = endTime.hour.map({ $0 * 60 + (endTime.minute ?? 0) }) else {
            return false
        }
        
        if startMinutes < endMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
}

extension NotificationPreferences {
    static var `default`: NotificationPreferences {
        return NotificationPreferences()
    }
}