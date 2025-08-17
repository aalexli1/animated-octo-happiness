# AR Treasure Hunt

An iOS app that uses ARKit and CoreLocation to create an augmented reality treasure hunting experience.

## Features

- **Map View**: See treasure locations on a map with real-time distance tracking
- **AR View**: Discover treasures in augmented reality using your device's camera
- **Location-Based AR**: Treasures appear at real GPS coordinates
- **Proximity Detection**: Automatically collect treasures when you get close
- **Progress Tracking**: Keep track of found treasures
- **AR Coaching**: Built-in guidance for optimal AR experience

## Demo

The app includes 3 sample treasures located in San Francisco:
1. **Golden Star** - Near the water
2. **Diamond Gem** - Hidden in the park
3. **Ancient Coin** - Near the old building

### How to Use

1. **Launch the app** - Opens to the map view showing treasure locations
2. **Grant permissions** - Allow camera and location access when prompted
3. **Find nearby treasures** - Treasures within 100m will appear in the "Nearby Treasures" list
4. **Switch to AR** - Tap "Open AR View" when treasures are nearby
5. **Hunt treasures** - Look around in AR to spot floating treasure symbols
6. **Collect** - Get within 5 meters of a treasure to automatically collect it
7. **Complete the hunt** - Find all treasures to win!

## Technical Implementation

### Architecture
- **SwiftUI** for UI with UIViewRepresentable for AR integration
- **ARKit** with ARWorldTrackingConfiguration for AR sessions
- **CoreLocation** for GPS positioning and distance calculations  
- **MapKit** for map visualization
- **SceneKit** for 3D treasure rendering

### Key Components
- `TreasureHuntView`: Main coordinator managing map/AR view switching
- `ARTreasureView`: AR view with treasure detection and collection
- `MapTreasureView`: Map showing treasure locations and distances
- `LocationManager`: Handles GPS updates and distance calculations
- `Treasure`: Data model for treasure information

### Permissions Required
- Camera access for AR view
- Location access (When In Use) for treasure positioning

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

## Requirements

- iOS 14.0+
- iPhone with A12 processor or later (for ARKit)
- Location services enabled
- Camera access

## Future Enhancements

- Network-based treasure loading
- Multiplayer competitions
- Custom treasure creation
- Achievement system
- Offline mode with cached treasures
