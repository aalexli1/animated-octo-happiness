# Treasure Hunt iOS App

An AR-based treasure hunting app where users can create and discover virtual treasures in the real world.

## Features

- **Treasure Creation**: Multi-step workflow to create treasures with custom messages and photos
- **Photo Integration**: Capture photos with camera or select from photo library
- **Emoji Customization**: Choose from 30+ emojis to represent your treasure
- **Location-Based**: Treasures are placed at your current GPS location
- **Map View**: See all treasures on an interactive map
- **Treasure Discovery**: Find and mark treasures as discovered
- **Data Persistence**: All treasures are saved locally

## Demo Instructions

### Running the App

1. Open `animated-octo-happiness-ios.xcodeproj` in Xcode
2. Select your target device (iPhone simulator or physical device)
3. Click the Run button or press `Cmd+R`

### Creating a Treasure

1. Tap the blue **+** button on the main map screen
2. **Step 1 - Details**: Enter a title and message for your treasure
3. **Step 2 - Photo** (Optional): Take a photo or select from library
4. **Step 3 - Icon**: Choose an emoji to represent your treasure on the map
5. **Step 4 - Preview**: Review your treasure before creating
6. Tap **Create Treasure** to place it at your current location

### Finding Treasures

1. Browse the map to see treasure icons
2. Tap on a treasure icon to view details
3. Read the message and view any attached photos
4. Mark the treasure as "Found" when discovered

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Location services permission
- Camera permission (for photo capture)
- Photo library permission (for photo selection)

## Permissions

The app will request the following permissions:
- **Location**: To place and find treasures at real-world locations
- **Camera**: To capture photos for treasures
- **Photo Library**: To select existing photos for treasures

## Technical Stack

- SwiftUI for UI
- MapKit for map functionality
- CoreLocation for GPS services
- PhotosUI for photo selection
- UIImagePickerController for camera access

## Project Structure

```
animated-octo-happiness-ios/
├── Models/
│   └── Treasure.swift
├── Views/
│   ├── ContentView.swift
│   ├── TreasureCreationView.swift
│   ├── TreasureDetailsView.swift
│   ├── PhotoSelectionView.swift
│   ├── EmojiSelectionView.swift
│   ├── TreasurePreviewView.swift
│   ├── TreasureDetailView.swift
│   └── ImagePicker.swift
├── ViewModels/
│   └── TreasureCreationViewModel.swift
└── Services/
    └── TreasureStore.swift
```

## Known Limitations

- Treasures are stored locally on device (not synced across devices)
- Location accuracy depends on device GPS capabilities
- Photo storage is limited by device storage capacity

## Future Enhancements

- Cloud synchronization for cross-device treasure sharing
- AR view for treasure discovery (#5)
- Social features for sharing treasures with friends
- Treasure categories and filtering
- Achievement system for finding treasures