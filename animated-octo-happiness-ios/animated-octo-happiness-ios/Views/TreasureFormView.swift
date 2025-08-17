//
//  TreasureFormView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData
import CoreLocation

struct TreasureFormView: View {
    enum Mode {
        case create
        case edit(Treasure)
        
        var title: String {
            switch self {
            case .create:
                return "New Treasure"
            case .edit:
                return "Edit Treasure"
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TreasureFormViewModel()
    @State private var showingLocationPicker = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
    let mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $viewModel.title)
                        .onChange(of: viewModel.title) { _ in
                            _ = viewModel.validateTitle()
                        }
                    
                    if let error = viewModel.titleError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: viewModel.description) { _ in
                            _ = viewModel.validateDescription()
                        }
                    
                    if let error = viewModel.descriptionError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Location") {
                    HStack {
                        TextField("Latitude", text: $viewModel.latitude)
                            .keyboardType(.decimalPad)
                            .onChange(of: viewModel.latitude) { _ in
                                _ = viewModel.validateCoordinates()
                            }
                        
                        TextField("Longitude", text: $viewModel.longitude)
                            .keyboardType(.decimalPad)
                            .onChange(of: viewModel.longitude) { _ in
                                _ = viewModel.validateCoordinates()
                            }
                    }
                    
                    if let error = viewModel.coordinateError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: useCurrentLocation) {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                }
                
                Section("Additional Information") {
                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Toggle("Collected", isOn: $viewModel.isCollected)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTreasure()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $showingSaveError) {
                Button("OK") {}
            } message: {
                Text(saveErrorMessage)
            }
            .onAppear {
                if case .edit(let treasure) = mode {
                    viewModel = TreasureFormViewModel(treasure: treasure)
                }
            }
        }
    }
    
    private func useCurrentLocation() {
        viewModel.setCurrentLocation(
            CLLocationCoordinate2D(
                latitude: 37.7749,
                longitude: -122.4194
            )
        )
    }
    
    private func saveTreasure() {
        guard viewModel.isValid else { return }
        
        do {
            switch mode {
            case .create:
                let treasure = Treasure(
                    title: viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
                    latitude: Double(viewModel.latitude) ?? 0,
                    longitude: Double(viewModel.longitude) ?? 0,
                    isCollected: viewModel.isCollected,
                    notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                    imageData: viewModel.imageData
                )
                modelContext.insert(treasure)
                
            case .edit(let treasure):
                treasure.title = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
                treasure.treasureDescription = viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines)
                treasure.latitude = Double(viewModel.latitude) ?? treasure.latitude
                treasure.longitude = Double(viewModel.longitude) ?? treasure.longitude
                treasure.isCollected = viewModel.isCollected
                treasure.notes = viewModel.notes.isEmpty ? nil : viewModel.notes
                if let imageData = viewModel.imageData {
                    treasure.imageData = imageData
                }
            }
            
            try modelContext.save()
            dismiss()
            
        } catch {
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}

#Preview("Create Mode") {
    TreasureFormView(mode: .create)
        .modelContainer(for: Treasure.self, inMemory: true)
}

#Preview("Edit Mode") {
    TreasureFormView(mode: .edit(Treasure.preview))
        .modelContainer(for: Treasure.self, inMemory: true)
}