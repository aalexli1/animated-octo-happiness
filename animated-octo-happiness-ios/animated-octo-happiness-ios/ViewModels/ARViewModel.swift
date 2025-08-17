//
//  ARViewModel.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/17/25.
//

import Foundation
import RealityKit
import ARKit
import Combine
import AVFoundation
import UIKit

class ARViewModel: ObservableObject {
    @Published var score = 0
    @Published var treasuresFound = 0
    @Published var totalTreasures = 0
    @Published var isSoundEnabled = true
    @Published var nearestTreasureDistance: Float?
    
    private var arView: ARView?
    private var treasures: [TreasureEntity] = []
    private var audioPlayer: AVAudioPlayer?
    private var userPosition: SIMD3<Float> = [0, 0, 0]
    private var cancellables = Set<AnyCancellable>()
    private let hapticGenerator = UINotificationFeedbackGenerator()
    
    private let treasureManager = TreasureManager()
    
    func setupAR(arView: ARView) {
        self.arView = arView
        
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)
        
        placeTreasures(in: anchor)
        
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNearestTreasureDistance()
            }
            .store(in: &cancellables)
    }
    
    private func placeTreasures(in anchor: AnchorEntity) {
        treasures.removeAll()
        
        let treasureData = treasureManager.generateTreasures(count: 10)
        totalTreasures = treasureData.count
        
        for treasure in treasureData {
            let treasureEntity = TreasureEntity(treasure: treasure)
            anchor.addChild(treasureEntity)
            treasures.append(treasureEntity)
        }
    }
    
    func collectTreasure(_ entity: TreasureEntity) {
        guard !entity.treasure.isDiscovered else { return }
        
        entity.treasure.isDiscovered = true
        treasuresFound += 1
        score += entity.treasure.type.points
        
        playCollectionSound()
        triggerHapticFeedback()
        
        entity.playOpeningAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            entity.isEnabled = false
            entity.removeFromParent()
        }
        
        if treasuresFound == totalTreasures {
            completeGame()
        }
    }
    
    func updateUserPosition(_ transform: simd_float4x4) {
        userPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    private func updateNearestTreasureDistance() {
        var minDistance: Float = Float.greatestFiniteMagnitude
        
        for treasure in treasures where !treasure.treasure.isDiscovered {
            let distance = simd_distance(userPosition, treasure.position)
            if distance < minDistance {
                minDistance = distance
            }
        }
        
        nearestTreasureDistance = minDistance == Float.greatestFiniteMagnitude ? nil : minDistance
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    func showHint() {
        guard let nearest = findNearestUndiscoveredTreasure() else { return }
        
        let direction = normalize(nearest.position - userPosition)
        
        if let arView = arView {
            let hintEntity = createHintArrow(direction: direction)
            let anchor = AnchorEntity(world: userPosition + direction * 0.5)
            anchor.addChild(hintEntity)
            arView.scene.addAnchor(anchor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                anchor.removeFromParent()
            }
        }
    }
    
    private func findNearestUndiscoveredTreasure() -> TreasureEntity? {
        return treasures
            .filter { !$0.treasure.isDiscovered }
            .min { simd_distance(userPosition, $0.position) < simd_distance(userPosition, $1.position) }
    }
    
    private func createHintArrow(direction: SIMD3<Float>) -> Entity {
        let arrow = Entity()
        
        let mesh = MeshResource.generateCone(height: 0.2, radius: 0.05)
        var material = SimpleMaterial()
        material.color = .init(tint: .systemGreen, texture: nil)
        // Emissive color not available in SimpleMaterial, using metallic for glow effect
        material.metallic = 0.8
        
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        arrow.components.set(modelComponent)
        
        let angle = atan2(direction.x, direction.z)
        arrow.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        
        return arrow
    }
    
    func resetTreasures() {
        guard let arView = arView else { return }
        
        score = 0
        treasuresFound = 0
        
        for treasure in treasures {
            treasure.removeFromParent()
        }
        
        if let anchor = arView.scene.anchors.first as? AnchorEntity {
            placeTreasures(in: anchor)
        }
    }
    
    private func playCollectionSound() {
        guard isSoundEnabled else { return }
        
        AudioServicesPlaySystemSound(1104)
        
        guard let url = Bundle.main.url(forResource: "collect", withExtension: "wav") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    private func triggerHapticFeedback() {
        hapticGenerator.prepare()
        hapticGenerator.notificationOccurred(.success)
    }
    
    private func completeGame() {
        triggerHapticFeedback()
        AudioServicesPlaySystemSound(1025)
    }
}

class TreasureManager {
    func generateTreasures(count: Int) -> [ARTreasure] {
        var treasures: [ARTreasure] = []
        
        for _ in 0..<count {
            let type = TreasureType.allCases.randomElement()!
            let x = Float.random(in: -3...3)
            let z = Float.random(in: -3...3)
            let position = SIMD3<Float>(x, 0.1, z)
            
            let treasure = ARTreasure(type: type, position: position)
            treasures.append(treasure)
        }
        
        return treasures
    }
}