//
//  TreasurePreviewView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI
import MapKit

struct TreasurePreviewView: View {
    @ObservedObject var viewModel: TreasureCreationViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Preview Your Treasure")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(viewModel.selectedEmoji)
                            .font(.system(size: 50))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.treasureTitle)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Created by you")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Message", systemImage: "message.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.treasureMessage)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    if let image = viewModel.selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Photo Attachment", systemImage: "photo.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Location", systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Map(coordinateRegion: $region, annotationItems: [mockTreasure]) { treasure in
                            MapAnnotation(coordinate: treasure.coordinate) {
                                VStack {
                                    Text(viewModel.selectedEmoji)
                                        .font(.title)
                                        .padding(8)
                                        .background(Circle().fill(Color.white))
                                        .shadow(radius: 3)
                                    
                                    Image(systemName: "triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .rotationEffect(.degrees(180))
                                        .offset(y: -5)
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(8)
                        .disabled(true)
                    }
                }
                .padding()
                
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    
                    Text("Your treasure is ready!")
                        .font(.headline)
                    
                    Text("Tap 'Create Treasure' to place it at your current location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            updateMapRegion()
        }
    }
    
    private var mockTreasure: Treasure {
        Treasure(
            title: viewModel.treasureTitle,
            description: viewModel.treasureMessage,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            emoji: viewModel.selectedEmoji
        )
    }
    
    private func updateMapRegion() {
        if let location = viewModel.currentLocation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}