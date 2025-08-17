//
//  TreasureDetailView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI
import MapKit

struct TreasureDetailView: View {
    let treasure: Treasure
    let treasureStore: TreasureStore
    @Environment(\.dismiss) private var dismiss
    @State private var photoData: Data?
    @State private var showingFoundAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(treasure.emoji ?? "🎁")
                            .font(.system(size: 60))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(treasure.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.secondary)
                                Text("Created by \(treasure.createdBy)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if treasure.isCollected {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Found by \(treasure.createdBy ?? "Unknown")")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Message", systemImage: "message.fill")
                            .font(.headline)
                        
                        Text(treasure.treasureDescription)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    if let photoData = photoData,
                       let uiImage = UIImage(data: photoData) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Photo", systemImage: "photo.fill")
                                .font(.headline)
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Location", systemImage: "location.fill")
                            .font(.headline)
                        
                        Map(coordinateRegion: .constant(
                            MKCoordinateRegion(
                                center: treasure.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        ), annotationItems: [treasure]) { item in
                            MapMarker(coordinate: item.coordinate, tint: .blue)
                        }
                        .frame(height: 200)
                        .cornerRadius(8)
                        .disabled(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("Created \(treasure.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if treasure.isCollected {
                            HStack {
                                Image(systemName: "flag.checkered")
                                    .foregroundStyle(.secondary)
                                Text("Collected \(treasure.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    if !treasure.isCollected {
                        Button {
                            markAsFound()
                        } label: {
                            Label("Mark as Found", systemImage: "flag.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .navigationTitle("Treasure Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPhotoData()
        }
        .alert("Treasure Found!", isPresented: $showingFoundAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Congratulations! You've found this treasure!")
        }
    }
    
    private func loadPhotoData() {
        photoData = treasureStore.loadPhotoData(for: treasure)
    }
    
    private func markAsFound() {
        Task {
            try? await treasureStore.markTreasureAsFound(treasure, foundBy: UIDevice.current.name)
            showingFoundAlert = true
        }
    }
}

#Preview {
    TreasureDetailView(
        treasure: Treasure.sampleTreasure,
        treasureStore: TreasureStore()
    )
}