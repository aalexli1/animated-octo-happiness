//
//  TreasureCreationViewModel.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreLocation

enum CreationStep: Int, CaseIterable {
    case details = 0
    case photo
    case emoji
    case preview
    
    var title: String {
        switch self {
        case .details:
            return "Treasure Details"
        case .photo:
            return "Add Photo"
        case .emoji:
            return "Choose Icon"
        case .preview:
            return "Preview"
        }
    }
    
    var nextButtonTitle: String {
        switch self {
        case .preview:
            return "Create Treasure"
        default:
            return "Next"
        }
    }
}

@MainActor
class TreasureCreationViewModel: ObservableObject {
    @Published var currentStep: CreationStep = .details
    @Published var treasureTitle: String = ""
    @Published var treasureMessage: String = ""
    @Published var selectedEmoji: String = "🎁"
    @Published var selectedImage: UIImage?
    @Published var selectedImageItem: PhotosPickerItem?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var currentLocation: CLLocation?
    
    let availableEmojis = ["🎁", "💎", "🏆", "⭐️", "🎯", "🎪", "🎨", "🎭", "🎪", "🌟", 
                          "💝", "🎉", "🎊", "🎈", "🏅", "🥇", "👑", "💍", "🔮", "🗝️",
                          "📦", "🎀", "🎯", "🎲", "🎮", "🧩", "🎪", "🏰", "🗿", "🌈"]
    
    var canProceed: Bool {
        switch currentStep {
        case .details:
            return !treasureTitle.isEmpty && !treasureMessage.isEmpty
        case .photo:
            return true
        case .emoji:
            return !selectedEmoji.isEmpty
        case .preview:
            return true
        }
    }
    
    var progressValue: Double {
        Double(currentStep.rawValue + 1) / Double(CreationStep.allCases.count)
    }
    
    func nextStep() {
        guard canProceed else { return }
        
        if let nextIndex = CreationStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextIndex
            }
        }
    }
    
    func previousStep() {
        if let previousIndex = CreationStep(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = previousIndex
            }
        }
    }
    
    func loadImage() async {
        guard let item = selectedImageItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = uiImage
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    func createTreasure() async -> Treasure? {
        isLoading = true
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let location = currentLocation else {
            await MainActor.run {
                errorMessage = "Location not available"
                showingError = true
            }
            return nil
        }
        
        var photoData: Data?
        if let image = selectedImage {
            photoData = image.jpegData(compressionQuality: 0.7)
        }
        
        let treasure = Treasure(
            title: treasureTitle,
            description: treasureMessage,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            imageData: photoData,
            emoji: selectedEmoji,
            createdBy: UIDevice.current.name
        )
        
        return treasure
    }
    
    func reset() {
        currentStep = .details
        treasureTitle = ""
        treasureMessage = ""
        selectedEmoji = "🎁"
        selectedImage = nil
        selectedImageItem = nil
        errorMessage = nil
    }
}