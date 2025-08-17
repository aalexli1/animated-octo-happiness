# AR Treasure Hunt

An iOS app that uses ARKit and CoreLocation to create an augmented reality treasure hunting experience.

## Features

### Core Features
- **Map View**: See treasure locations on a map with real-time distance tracking
- **AR View**: Discover treasures in augmented reality using your device's camera
- **Location-Based AR**: Treasures appear at real GPS coordinates
- **Proximity Detection**: Automatically collect treasures when you get close
- **Progress Tracking**: Keep track of found treasures
- **AR Coaching**: Built-in guidance for optimal AR experience

### Social Features
- **Friend System**: Connect with friends to share treasures and compete
- **Friend Requests**: Send and receive friend requests with custom messages
- **Treasure Sharing**: Share treasures with specific friends or make them public
- **Groups**: Create or join treasure hunting groups with invite codes
- **Privacy Controls**: Set treasure visibility (public, friends-only, group-only, private)
- **Activity Feed**: See when friends find treasures or complete challenges
- **Block/Unblock**: Manage unwanted connections

## Demo

The app includes 3 sample treasures located in San Francisco:
1. **Golden Star** - Near the water
2. **Diamond Gem** - Hidden in the park
3. **Ancient Coin** - Near the old building

### How to Use

#### Treasure Hunting
1. **Launch the app** - Opens to the map view showing treasure locations
2. **Grant permissions** - Allow camera and location access when prompted
3. **Find nearby treasures** - Treasures within 100m will appear in the "Nearby Treasures" list
4. **Switch to AR** - Tap "Open AR View" when treasures are nearby
5. **Hunt treasures** - Look around in AR to spot floating treasure symbols
6. **Collect** - Get within 5 meters of a treasure to automatically collect it
7. **Complete the hunt** - Find all treasures to win!

#### Social Features
1. **Add Friends** - Go to Social tab > Friends > Add Friend
2. **Search Users** - Search by username or display name
3. **Send Request** - Select a user and optionally add a message
4. **Accept Requests** - Review pending requests in the Requests tab
5. **Create Group** - Social tab > Groups > Create Group
6. **Join Group** - Enter a 6-character invite code
7. **Share Treasures** - Long-press a treasure and select "Share"
8. **Set Privacy** - Choose who can see your treasures

## Technical Implementation

### Architecture
- **SwiftUI** for UI with UIViewRepresentable for AR integration
- **ARKit** with ARWorldTrackingConfiguration for AR sessions
- **CoreLocation** for GPS positioning and distance calculations  
- **MapKit** for map visualization
- **SceneKit** for 3D treasure rendering

### Key Components

#### Core Components
- `TreasureHuntView`: Main coordinator managing map/AR view switching
- `ARTreasureView`: AR view with treasure detection and collection
- `MapTreasureView`: Map showing treasure locations and distances
- `LocationManager`: Handles GPS updates and distance calculations
- `Treasure`: Data model for treasure information with privacy settings

#### Social Components
- `User`: User profile with friends and group memberships
- `FriendService`: Manages friend relationships and requests
- `GroupService`: Handles group creation and management
- `FriendsListView`: Interface for managing friends and requests
- `GroupsView`: Create and manage treasure hunting groups
- `ActivityFeedView`: Timeline of friend activities
- `TreasureSharingView`: Configure treasure privacy and sharing

### Permissions Required
- Camera access for AR view
- Location access (When In Use) for treasure positioning
- Notifications (optional) for friend requests and treasure updates

## Testing

Run the test suite:
```bash
xcodebuild test -scheme animated-octo-happiness-ios
```

Tests include:
- Location distance calculations
- Bearing calculations
- Nearby treasure filtering
- Treasure model validation
- Friend system operations
- Group management
- Privacy settings
- Activity feed functionality

## Requirements

- iOS 14.0+
- iPhone with A12 processor or later (for ARKit)
- Location services enabled
- Camera access

## Privacy & Sharing

### Privacy Levels
- **Public**: Anyone can see and find the treasure
- **Friends Only**: Only your friends can see the treasure
- **Group Only**: Only members of a specific group can access
- **Private**: Only you can see the treasure

### Group Features
- Create groups with custom names and emojis
- Set maximum member limits
- Generate unique 6-character invite codes
- Share treasures exclusively with group members
- Remove members (owner only)
- Leave or delete groups

## Future Enhancements

- Network-based treasure loading
- Multiplayer competitions
- Custom treasure creation
- Achievement system
- Offline mode with cached treasures
- Real-time treasure updates
- Friend leaderboards
- Group challenges
