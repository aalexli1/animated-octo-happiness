//
//  ImportExportView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportedData: Data?
    @State private var exportFileName = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Export Treasures", systemImage: "square.and.arrow.up")
                            .font(.headline)
                        Text("Save your treasures and profiles to a file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        exportData()
                    }
                } header: {
                    Text("Export")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Import Treasures", systemImage: "square.and.arrow.down")
                            .font(.headline)
                        Text("Load treasures from a file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingImportPicker = true
                    }
                } header: {
                    Text("Import")
                }
                
                Section {
                    DataSummaryView()
                } header: {
                    Text("Current Data")
                }
                
                Section {
                    Text("Export format: JSON")
                    Text("Compatible with: Treasure Hunt v1.0+")
                    Text("Includes: Treasures, Profiles, Statistics")
                } header: {
                    Text("Information")
                } footer: {
                    Text("Exported files can be shared with other players or used as backups. Import will add new treasures without removing existing ones.")
                }
            }
            .navigationTitle("Import & Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if isProcessing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Processing...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportedData {
                    ShareSheet(activityItems: [
                        TreasureExportDocument(data: data, fileName: exportFileName)
                    ])
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func exportData() {
        isProcessing = true
        
        Task {
            do {
                let data = try await persistenceManager.exportTreasures()
                await MainActor.run {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: Date())
                    exportFileName = "treasures_\(dateString).json"
                    exportedData = data
                    showingExportSheet = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Export Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importData(from: url)
            
        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func importData(from url: URL) {
        isProcessing = true
        
        Task {
            do {
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                try await persistenceManager.importTreasures(from: data)
                
                await MainActor.run {
                    alertTitle = "Import Successful"
                    alertMessage = "Treasures have been imported successfully!"
                    showingAlert = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Import Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
}

struct DataSummaryView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(persistenceManager.treasures.count)", systemImage: "mappin.circle.fill")
                    .foregroundColor(.blue)
                Text("Total Treasures")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Label("\(persistenceManager.allProfiles.count)", systemImage: "person.2.fill")
                    .foregroundColor(.green)
                Text("Player Profiles")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if let profile = persistenceManager.currentProfile {
                HStack {
                    Label("\(profile.treasuresFound?.count ?? 0)", systemImage: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Found by \(profile.name)")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Label("\(profile.treasuresCreated?.count ?? 0)", systemImage: "plus.circle.fill")
                        .foregroundColor(.purple)
                    Text("Created by \(profile.name)")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
}

struct TreasureExportDocument: NSObject, UIActivityItemSource {
    let data: Data
    let fileName: String
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return tempURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Treasure Hunt Export"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ImportExportView()
        .environmentObject(PersistenceManager.shared)
}