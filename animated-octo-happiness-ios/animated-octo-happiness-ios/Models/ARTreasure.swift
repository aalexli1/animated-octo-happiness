//
//  ARTreasure.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/17/25.
//

import Foundation
import RealityKit
import ARKit

enum TreasureType: String, CaseIterable, Codable {
    case gold = "Gold"
    case silver = "Silver"
    case bronze = "Bronze"
    case gem = "Gem"
    case artifact = "Artifact"
    
    var points: Int {
        switch self {
        case .gold: return 100
        case .silver: return 50
        case .bronze: return 25
        case .gem: return 75
        case .artifact: return 150
        }
    }
    
    var color: UIColor {
        switch self {
        case .gold: return .systemYellow
        case .silver: return .systemGray
        case .bronze: return .systemBrown
        case .gem: return .systemPurple
        case .artifact: return .systemTeal
        }
    }
}

struct ARTreasure: Identifiable, Codable {
    let id: UUID
    let type: TreasureType
    var isDiscovered: Bool
    let position: SIMD3<Float>
    let discoveryRadius: Float
    
    init(id: UUID = UUID(), type: TreasureType, position: SIMD3<Float>, discoveryRadius: Float = 0.5) {
        self.id = id
        self.type = type
        self.isDiscovered = false
        self.position = position
        self.discoveryRadius = discoveryRadius
    }
}

class TreasureEntity: Entity {
    var treasure: ARTreasure
    var animationController: AnimationResource?
    
    init(treasure: ARTreasure) {
        self.treasure = treasure
        super.init()
        setupModel()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    private func setupModel() {
        let mesh = MeshResource.generateBox(size: 0.1)
        var material = SimpleMaterial()
        material.color = .init(tint: treasure.type.color, texture: nil)
        material.metallic = 0.8
        material.roughness = 0.2
        
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        self.components.set(modelComponent)
        
        let collisionShape = ShapeResource.generateBox(size: [0.1, 0.1, 0.1])
        let collisionComponent = CollisionComponent(shapes: [collisionShape])
        self.components.set(collisionComponent)
        
        self.position = treasure.position
    }
    
    func playOpeningAnimation() {
        var transform = self.transform
        transform.scale = [1.5, 1.5, 1.5]
        
        self.move(to: transform, relativeTo: self.parent, duration: 0.3, timingFunction: .easeInOut)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            transform.scale = [0.01, 0.01, 0.01]
            self.move(to: transform, relativeTo: self.parent, duration: 0.5, timingFunction: .easeIn)
        }
    }
}