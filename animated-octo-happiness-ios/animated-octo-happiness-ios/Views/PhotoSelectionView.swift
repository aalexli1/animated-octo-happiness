//
//  PhotoSelectionView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI
import PhotosUI

struct PhotoSelectionView: View {
    @ObservedObject var viewModel: TreasureCreationViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Add a photo to your treasure")
                    .font(.headline)
                    .padding(.top)
                
                Text("Optional: Include a photo that will be revealed when the treasure is found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding()
                    
                    Button("Remove Photo", role: .destructive) {
                        withAnimation {
                            viewModel.selectedImage = nil
                            viewModel.selectedImageItem = nil
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        HStack(spacing: 20) {
                            Button {
                                sourceType = .camera
                                showingCamera = true
                            } label: {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Camera")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            
                            PhotosPicker(selection: $viewModel.selectedImageItem,
                                       matching: .images) {
                                VStack {
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                    Text("Library")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 40)
                }
                
                Text("Tip: Photos make treasures more personal and memorable!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding()
                    .background(Color(.systemYellow).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .onChange(of: viewModel.selectedImageItem) { _, _ in
            Task {
                await viewModel.loadImage()
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: sourceType)
        }
    }
}