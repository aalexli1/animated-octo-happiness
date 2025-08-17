# Offline-First Architecture

## Overview

The AR Treasure Discovery app implements a comprehensive offline-first architecture that ensures full functionality without internet connectivity and seamless synchronization when connected.

## Key Components

### 1. Network Monitor (`NetworkMonitor.swift`)
- Real-time network status detection using Apple's Network framework
- Monitors connection type (WiFi, Cellular, Ethernet)
- Detects expensive and constrained connections
- Provides callbacks for network state changes

### 2. Operation Queue (`OfflineOperationQueue.swift`)
- Persistent queue for offline operations
- Supports CRUD operations: Create, Update, Delete, Mark as Collected
- Automatic retry with exponential backoff
- Operations persist across app launches using UserDefaults

### 3. Sync Manager (`SyncManager.swift`)
- Bidirectional sync with pull-then-push strategy
- Conflict resolution with multiple strategies:
  - Client Wins
  - Server Wins
  - Last Write Wins
  - Merge (combines non-conflicting fields)
- Progress tracking and error handling
- Periodic sync every 30 seconds when online

### 4. Cache Manager (`CacheManager.swift`)
- Multi-tiered caching system
- Type-specific policies (images, treasure data, map tiles, AR assets)
- LRU eviction strategy
- Version tracking for cache invalidation
- Automatic pruning based on age and size limits

### 5. Background Sync (`BackgroundSyncManager.swift`)
- Background processing tasks for sync
- App refresh for lightweight updates
- Battery-efficient scheduling
- Network-aware task execution

### 6. Offline Service (`OfflineTreasureService.swift`)
- Extends base TreasureService with offline capabilities
- Automatic queuing of operations when offline
- Transparent caching of data and images
- Preloading of nearby treasures for offline access

## Features

### Full Offline Functionality
- Create, edit, and delete treasures without internet
- View and interact with cached treasures
- AR experiences work with cached data
- Map functionality with offline tiles

### Smart Sync
- Automatic sync when connection restored
- Background sync when app is not in use
- Conflict detection and resolution
- Progress indicators and status updates

### Data Consistency
- Versioning system for data integrity
- Transactional operations
- Rollback capability for failed syncs
- Audit trail for all operations

### Battery Optimization
- Batch operations to reduce network calls
- Respect expensive connection settings
- Adaptive sync intervals based on battery level
- Efficient background task scheduling

## Usage

### Basic Setup

```swift
// In your App file
@StateObject private var networkMonitor = NetworkMonitor.shared
@StateObject private var operationQueue = OfflineOperationQueue(networkMonitor: networkMonitor)
@StateObject private var syncManager = SyncManager(
    modelContext: modelContext,
    networkMonitor: networkMonitor,
    operationQueue: operationQueue
)
```

### Creating Offline-Capable Operations

```swift
// Create treasure (works offline)
let treasure = try offlineService.createTreasure(
    title: "Hidden Gem",
    description: "A beautiful treasure",
    coordinate: coordinate
)

// Update treasure (queued if offline)
try offlineService.updateTreasure(
    treasure,
    title: "Updated Title"
)

// Delete treasure (synced when online)
try offlineService.deleteTreasure(treasure)
```

### Monitoring Sync Status

```swift
// In your view
SyncStatusView(
    syncManager: syncManager,
    networkMonitor: networkMonitor,
    operationQueue: operationQueue
)

// Check sync status programmatically
let status = syncManager.getSyncStatus()
let pendingOps = operationQueue.getPendingOperationsCount()
```

### Handling Conflicts

```swift
// Configure conflict resolution strategy
let resolution = syncManager.resolveConflict(
    local: localPayload,
    server: serverPayload,
    strategy: .lastWriteWins  // or .clientWins, .serverWins, .merge
)
```

### Cache Management

```swift
// Cache treasure data
cacheManager.cacheTreasureData(treasure)

// Cache images
cacheManager.cacheImage(image, forKey: treasure.id.uuidString)

// Check cache info
let (size, items) = cacheManager.getCacheInfo()

// Clear cache
cacheManager.clearCache(for: .images)  // Clear specific type
cacheManager.clearCache()  // Clear all
```

## Demo

Run the offline-first demo to see all features in action:

1. Open `OfflineFirstDemo.swift` in the Demo folder
2. Run the app and navigate to the demo view
3. Toggle "Simulate Offline" to test offline mode
4. Create treasures while offline
5. Simulate conflicts and resolutions
6. Monitor sync status and queue
7. Test background sync simulation

## Testing

Comprehensive test suite available in `OfflineArchitectureTests.swift`:

- Network monitoring tests
- Operation queue persistence tests
- Conflict resolution tests
- Cache management tests
- Performance tests for large datasets
- Background sync tests

Run tests with:
```bash
xcodebuild test -scheme animated-octo-happiness-ios -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture Decisions

### Why Offline-First?
- Better user experience in areas with poor connectivity
- Reduced latency for all operations
- Lower server load through intelligent sync
- Resilience to network failures

### Why Operation Queue Pattern?
- Guarantees eventual consistency
- Allows complex operation ordering
- Provides audit trail
- Enables retry logic

### Why Multiple Conflict Resolution Strategies?
- Different data types need different strategies
- User preferences vary by use case
- Flexibility for future requirements
- Better handling of edge cases

## Performance Considerations

- Operations are batched to reduce network calls
- Cache pruning runs on background queue
- Sync operations use efficient delta updates
- Background tasks respect system resources

## Security

- All cached data is encrypted at rest
- Network operations use HTTPS
- Sensitive data is excluded from logs
- User data remains private and local-first

## Future Enhancements

- [ ] Selective sync based on user preferences
- [ ] Compression for large data transfers
- [ ] P2P sync between nearby devices
- [ ] Advanced conflict UI for user resolution
- [ ] Analytics for sync performance

## Troubleshooting

### Common Issues

1. **Sync not working**
   - Check network connectivity
   - Verify background refresh is enabled
   - Check for failed operations in queue

2. **Cache growing too large**
   - Adjust cache policies in CacheManager
   - Enable more aggressive pruning
   - Clear cache manually if needed

3. **Conflicts occurring frequently**
   - Review conflict resolution strategy
   - Consider implementing user-specific locks
   - Increase sync frequency

### Debug Tools

- Use `OfflineFirstDemo` for testing scenarios
- Monitor console logs for sync activity
- Check `syncManager.lastError` for issues
- Review operation queue for stuck items

## Support

For issues or questions about the offline-first architecture, please refer to:
- Technical documentation in code comments
- Test suite for usage examples
- Demo app for interactive testing