//
//  TreasureCreationView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct TreasureCreationView: View {
    @StateObject private var viewModel = TreasureCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingCancelAlert = false
    
    var onComplete: ((Treasure) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: viewModel.progressValue) {
                    Text(viewModel.currentStep.title)
                        .font(.headline)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .tint(.blue)
                
                TabView(selection: $viewModel.currentStep) {
                    TreasureDetailsView(viewModel: viewModel)
                        .tag(CreationStep.details)
                    
                    PhotoSelectionView(viewModel: viewModel)
                        .tag(CreationStep.photo)
                    
                    EmojiSelectionView(viewModel: viewModel)
                        .tag(CreationStep.emoji)
                    
                    TreasurePreviewView(viewModel: viewModel)
                        .tag(CreationStep.preview)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                
                HStack(spacing: 20) {
                    if viewModel.currentStep != .details {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentStep.nextButtonTitle) {
                        if viewModel.currentStep == .preview {
                            Task {
                                await createTreasure()
                            }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canProceed || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Create Treasure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }
            }
            .alert("Cancel Creation?", isPresented: $showingCancelAlert) {
                Button("Continue Editing", role: .cancel) { }
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to cancel? All changes will be lost.")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Creating treasure...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                        }
                }
            }
        }
        .onAppear {
            requestLocationPermission()
        }
    }
    
    private func createTreasure() async {
        if let treasure = await viewModel.createTreasure() {
            await MainActor.run {
                onComplete?(treasure)
                dismiss()
            }
        }
    }
    
    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.currentLocation = locationManager.location ?? CLLocation(latitude: 37.7749, longitude: -122.4194)
        }
    }
}