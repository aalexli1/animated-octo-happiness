//
//  ARTreasureHuntView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/17/25.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARTreasureHuntView: View {
    @StateObject private var arViewModel = ARViewModel()
    @State private var showDistanceHint = false
    @State private var currentHint = ""
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HUD(viewModel: arViewModel)
                
                Spacer()
                
                if showDistanceHint {
                    DistanceHintView(hint: currentHint)
                        .transition(.slide)
                }
                
                ControlPanel(viewModel: arViewModel)
            }
        }
        .onReceive(arViewModel.$nearestTreasureDistance) { distance in
            updateDistanceHint(distance: distance)
        }
    }
    
    private func updateDistanceHint(distance: Float?) {
        guard let distance = distance else {
            showDistanceHint = false
            return
        }
        
        showDistanceHint = true
        
        switch distance {
        case 0..<0.5:
            currentHint = "🔥 Very Hot! Treasure is right here!"
        case 0.5..<1.0:
            currentHint = "🌡️ Hot! You're very close!"
        case 1.0..<2.0:
            currentHint = "♨️ Warm! Getting closer..."
        case 2.0..<5.0:
            currentHint = "❄️ Cold. Keep searching..."
        default:
            currentHint = "🧊 Freezing! No treasures nearby."
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        viewModel.setupAR(arView: arView)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var viewModel: ARViewModel
        
        init(viewModel: ARViewModel) {
            self.viewModel = viewModel
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let location = recognizer.location(in: arView)
            
            if let entity = arView.entity(at: location) as? TreasureEntity {
                viewModel.collectTreasure(entity)
            }
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            viewModel.updateUserPosition(frame.camera.transform)
        }
    }
}

struct HUD: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Score: \(viewModel.score)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.orange)
                Text("Found: \(viewModel.treasuresFound)/\(viewModel.totalTreasures)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
        .padding()
    }
}

struct DistanceHintView: View {
    let hint: String
    
    var body: some View {
        Text(hint)
            .font(.subheadline)
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding()
    }
}

struct ControlPanel: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                viewModel.toggleSound()
            }) {
                Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            Button(action: {
                viewModel.showHint()
            }) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            
            Button(action: {
                viewModel.resetTreasures()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

#Preview {
    ARTreasureHuntView()
}