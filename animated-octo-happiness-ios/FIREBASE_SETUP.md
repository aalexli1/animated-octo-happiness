# Firebase Setup Guide

This guide will walk you through setting up Firebase for the Animated Octo Happiness iOS app.

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0+ deployment target
- Firebase account (create one at https://console.firebase.google.com)
- Apple Developer account (for push notifications)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create Project" or "Add Project"
3. Enter project name: `animated-octo-happiness`
4. Enable Google Analytics (optional but recommended)
5. Select or create a Google Analytics account
6. Click "Create Project"

## Step 2: Add iOS App to Firebase Project

1. In Firebase Console, click the iOS icon to add an iOS app
2. Register your app:
   - iOS Bundle ID: `com.example.animated-octo-happiness-ios` (or your actual bundle ID)
   - App nickname: `Animated Octo Happiness`
   - App Store ID: (leave blank for now)
3. Download `GoogleService-Info.plist`
4. Place the file in the project root: `animated-octo-happiness-ios/GoogleService-Info.plist`

## Step 3: Add Firebase SDK via Swift Package Manager

1. Open `animated-octo-happiness-ios.xcodeproj` in Xcode
2. Go to File → Add Package Dependencies
3. Enter the Firebase iOS SDK URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select version: Up to Next Major Version → 10.0.0
5. Add the following Firebase products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFirestoreSwift
   - FirebaseStorage
   - FirebaseMessaging
   - FirebaseAnalytics (optional)

## Step 4: Enable Firebase Services

### Authentication

1. In Firebase Console, go to Authentication → Sign-in method
2. Enable the following providers:
   - Email/Password
   - Anonymous (for guest users)
   - Sign in with Apple (requires Apple Developer configuration)

### Firestore Database

1. Go to Firestore Database → Create database
2. Choose production mode
3. Select your preferred location (e.g., us-central1)
4. Deploy security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Cloud Storage

1. Go to Storage → Get started
2. Choose production mode
3. Select your preferred location (same as Firestore)
4. Deploy storage rules:
   ```bash
   firebase deploy --only storage:rules
   ```

## Step 5: Configure Push Notifications

### Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com)
2. Go to Certificates, Identifiers & Profiles
3. Select your app identifier
4. Enable Push Notifications capability
5. Create an APNs Authentication Key:
   - Go to Keys → Create a new key
   - Name: `Firebase APNs`
   - Enable Apple Push Notifications service (APNs)
   - Download the `.p8` file and note the Key ID

### Firebase Console

1. Go to Project Settings → Cloud Messaging
2. Under iOS app configuration, upload the APNs Authentication Key:
   - Upload the `.p8` file
   - Enter the Key ID
   - Enter your Team ID

### Xcode Configuration

1. Select your project in Xcode
2. Go to Signing & Capabilities
3. Add Push Notifications capability
4. Add Background Modes capability and check:
   - Remote notifications
   - Background fetch

## Step 6: Environment Configuration

### Development Environment

1. Create `GoogleService-Info-Dev.plist` for development
2. Configure with development Firebase project
3. Use in DEBUG builds

### Production Environment

1. Use `GoogleService-Info.plist` for production
2. Configure with production Firebase project
3. Use in RELEASE builds

## Step 7: Update Code

1. Uncomment Firebase imports in all service files:
   - `FirebaseAuthService.swift`
   - `FirestoreService.swift`
   - `FirebaseStorageService.swift`
   - `PushNotificationService.swift`
   - `animated_octo_happiness_iosApp.swift`

2. Build and run the project to verify Firebase initialization

## Step 8: Firebase CLI Setup (Optional)

Install Firebase CLI for deploying rules and functions:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select:
# - Firestore
# - Storage
# - Functions (if needed)
# - Hosting (if needed)
```

## Step 9: Test Firebase Integration

### Test Authentication

```swift
// Sign up test
Task {
    do {
        try await FirebaseAuthService.shared.signUp(
            email: "test@example.com",
            password: "testPassword123",
            displayName: "Test User"
        )
        print("Sign up successful")
    } catch {
        print("Sign up failed: \(error)")
    }
}
```

### Test Firestore

```swift
// Create test treasure
Task {
    do {
        let treasure = Treasure(
            title: "Test Treasure",
            description: "Test description",
            latitude: 37.7749,
            longitude: -122.4194,
            creatorId: "testUser"
        )
        let id = try await FirestoreService.shared.createTreasure(treasure)
        print("Treasure created with ID: \(id)")
    } catch {
        print("Failed to create treasure: \(error)")
    }
}
```

### Test Storage

```swift
// Upload test image
Task {
    do {
        if let image = UIImage(systemName: "star.fill") {
            let url = try await FirebaseStorageService.shared.uploadImage(
                image,
                path: "test/image.jpg"
            )
            print("Image uploaded to: \(url)")
        }
    } catch {
        print("Failed to upload image: \(error)")
    }
}
```

## Security Best Practices

1. **Never commit** `GoogleService-Info.plist` to version control
2. **Use environment-specific** configuration files
3. **Implement proper** security rules for Firestore and Storage
4. **Enable App Check** for additional security
5. **Monitor usage** in Firebase Console
6. **Set up budget alerts** to avoid unexpected charges

## Troubleshooting

### Common Issues

1. **"No GoogleService-Info.plist file found"**
   - Ensure the file is added to the Xcode project
   - Check that it's included in the app bundle

2. **"Could not configure Firebase"**
   - Verify the bundle ID matches Firebase configuration
   - Check that all required Firebase packages are installed

3. **Push notifications not working**
   - Verify APNs configuration in Firebase Console
   - Check device has notifications enabled
   - Test on real device (not simulator)

4. **Firestore permission denied**
   - Review security rules
   - Ensure user is authenticated
   - Check Firebase Console for rule violations

## Resources

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth/ios/start)
- [Cloud Firestore Guide](https://firebase.google.com/docs/firestore/quickstart)
- [Cloud Storage Guide](https://firebase.google.com/docs/storage/ios/start)
- [Cloud Messaging Guide](https://firebase.google.com/docs/cloud-messaging/ios/client)

## Support

For issues specific to this implementation, check the project's issue tracker.
For Firebase-specific issues, visit [Firebase Support](https://firebase.google.com/support).