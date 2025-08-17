//
//  ARTreasureView.swift
//  animated-octo-happiness-ios
//
//  Created by Claude on 8/17/25.
//

import SwiftUI
import ARKit
import SceneKit
import CoreLocation

struct ARTreasureView: UIViewRepresentable {
    let treasures: [Treasure]
    @ObservedObject var locationManager: LocationManager
    @Binding var foundTreasures: Set<UUID>
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        context.coordinator.arView = arView
        context.coordinator.setupARSession()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updateTreasures(treasures, nearLocation: locationManager.currentLocation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        let parent: ARTreasureView
        weak var arView: ARSCNView?
        var treasureNodes: [UUID: SCNNode] = [:]
        var configuration: ARWorldTrackingConfiguration?
        
        init(_ parent: ARTreasureView) {
            self.parent = parent
        }
        
        func setupARSession() {
            guard let arView = arView else { return }
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            configuration.planeDetection = [.horizontal]
            
            if ARGeoTrackingConfiguration.isSupported {
                let geoConfig = ARGeoTrackingConfiguration()
                // worldAlignment is automatically set for ARGeoTrackingConfiguration
                arView.session.run(geoConfig, options: [.resetTracking, .removeExistingAnchors])
            } else {
                arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            }
            
            self.configuration = configuration
            setupCoachingOverlay()
        }
        
        func setupCoachingOverlay() {
            guard let arView = arView else { return }
            
            let coachingOverlay = ARCoachingOverlayView()
            coachingOverlay.session = arView.session
            coachingOverlay.delegate = self
            coachingOverlay.goal = .geoTracking
            coachingOverlay.activatesAutomatically = true
            
            arView.addSubview(coachingOverlay)
            coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                coachingOverlay.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
                coachingOverlay.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
                coachingOverlay.widthAnchor.constraint(equalTo: arView.widthAnchor),
                coachingOverlay.heightAnchor.constraint(equalTo: arView.heightAnchor)
            ])
        }
        
        func updateTreasures(_ treasures: [Treasure], nearLocation: CLLocation?) {
            guard let arView = arView,
                  let currentLocation = nearLocation else { return }
            
            for treasure in treasures {
                if parent.foundTreasures.contains(treasure.id) {
                    treasureNodes[treasure.id]?.removeFromParentNode()
                    treasureNodes.removeValue(forKey: treasure.id)
                    continue
                }
                
                if treasureNodes[treasure.id] == nil {
                    let node = createTreasureNode(for: treasure)
                    
                    let treasureLocation = CLLocation(
                        latitude: treasure.coordinate.latitude,
                        longitude: treasure.coordinate.longitude
                    )
                    
                    let distance = currentLocation.distance(from: treasureLocation)
                    guard distance <= 100 else { continue }
                    
                    let bearing = parent.locationManager.bearingToTreasure(treasure) ?? 0
                    let bearingRadians = bearing * .pi / 180
                    
                    let x = Float(sin(bearingRadians) * min(distance, 50))
                    let z = Float(-cos(bearingRadians) * min(distance, 50))
                    let y = Float(-1.5)
                    
                    node.position = SCNVector3(x, y, z)
                    arView.scene.rootNode.addChildNode(node)
                    treasureNodes[treasure.id] = node
                    
                    animateTreasureNode(node)
                }
            }
            
            for (id, node) in treasureNodes {
                if !treasures.contains(where: { $0.id == id }) {
                    node.removeFromParentNode()
                    treasureNodes.removeValue(forKey: id)
                }
            }
        }
        
        func createTreasureNode(for treasure: Treasure) -> SCNNode {
            let node = SCNNode()
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold)
            if let image = UIImage(systemName: "gift.fill", withConfiguration: symbolConfig) {
                let plane = SCNPlane(width: 0.3, height: 0.3)
                plane.firstMaterial?.diffuse.contents = image.withTintColor(UIColor.systemYellow, renderingMode: .alwaysOriginal)
                plane.firstMaterial?.isDoubleSided = true
                plane.firstMaterial?.emission.contents = UIColor.systemYellow.withAlphaComponent(0.3)
                
                let planeNode = SCNNode(geometry: plane)
                node.addChildNode(planeNode)
            }
            
            let text = SCNText(string: treasure.title, extrusionDepth: 0.01)
            text.font = UIFont.systemFont(ofSize: 0.05)
            text.firstMaterial?.diffuse.contents = UIColor.white
            text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(x: -0.15, y: -0.25, z: 0)
            node.addChildNode(textNode)
            
            node.name = treasure.id.uuidString
            
            return node
        }
        
        func animateTreasureNode(_ node: SCNNode) {
            let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4)
            let repeatAction = SCNAction.repeatForever(rotateAction)
            node.runAction(repeatAction)
            
            let floatUp = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 2)
            floatUp.timingMode = .easeInEaseOut
            let floatDown = SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 2)
            floatDown.timingMode = .easeInEaseOut
            let floatSequence = SCNAction.sequence([floatUp, floatDown])
            let floatForever = SCNAction.repeatForever(floatSequence)
            node.runAction(floatForever)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            return nil
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let currentLocation = parent.locationManager.currentLocation else { return }
            
            for (treasureId, node) in treasureNodes {
                guard let treasure = parent.treasures.first(where: { $0.id == treasureId }) else { continue }
                
                let treasureLocation = CLLocation(
                    latitude: treasure.coordinate.latitude,
                    longitude: treasure.coordinate.longitude
                )
                let distance = currentLocation.distance(from: treasureLocation)
                
                if distance < 5 && !parent.foundTreasures.contains(treasureId) {
                    DispatchQueue.main.async {
                        self.parent.foundTreasures.insert(treasureId)
                        self.playFoundAnimation(for: node)
                    }
                }
            }
        }
        
        func playFoundAnimation(for node: SCNNode) {
            let scaleUp = SCNAction.scale(to: 1.5, duration: 0.3)
            let fadeOut = SCNAction.fadeOut(duration: 0.5)
            let remove = SCNAction.removeFromParentNode()
            let sequence = SCNAction.sequence([scaleUp, fadeOut, remove])
            
            node.runAction(sequence)
            
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 100
            particleSystem.particleLifeSpan = 1
            particleSystem.particleSize = 0.05
            particleSystem.particleColor = UIColor.systemYellow
            particleSystem.spreadingAngle = 45
            particleSystem.particleVelocity = 2
            
            let particleNode = SCNNode()
            particleNode.position = node.position
            particleNode.addParticleSystem(particleSystem)
            arView?.scene.rootNode.addChildNode(particleNode)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                particleNode.removeFromParentNode()
            }
        }
    }
}