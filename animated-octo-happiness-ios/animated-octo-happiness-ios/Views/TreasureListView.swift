//
//  TreasureListView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct TreasureListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Treasure.timestamp, order: .reverse) private var treasures: [Treasure]
    @State private var viewModel: TreasureListViewModel?
    @State private var showingAddTreasure = false
    @State private var selectedTreasure: Treasure?
    @State private var showingDeleteAlert = false
    @State private var treasureToDelete: Treasure?
    
    var body: some View {
        NavigationStack {
            Group {
                if treasures.isEmpty {
                    emptyStateView
                } else {
                    treasureList
                }
            }
            .navigationTitle("Treasures")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTreasure = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !treasures.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddTreasure) {
                TreasureFormView(mode: .create)
            }
            .sheet(item: $selectedTreasure) { treasure in
                TreasureFormView(mode: .edit(treasure))
            }
            .alert("Delete Treasure", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let treasure = treasureToDelete {
                        deleteTreasure(treasure)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this treasure? This action cannot be undone.")
            }
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ))
            .onAppear {
                if viewModel == nil {
                    viewModel = TreasureListViewModel(modelContext: modelContext)
                }
                Task {
                    await viewModel?.loadTreasures()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Treasures Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start your treasure hunt by adding your first discovery!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddTreasure = true }) {
                Label("Add First Treasure", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var treasureList: some View {
        List {
            if let vm = viewModel {
                statisticsSection(vm.statistics)
                
                ForEach(vm.searchText.isEmpty ? treasures : vm.filteredTreasures) { treasure in
                    TreasureRowView(treasure: treasure)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTreasure = treasure
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                treasureToDelete = treasure
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            if !treasure.isCollected {
                                Button {
                                    Task {
                                        await viewModel?.markAsCollected(treasure)
                                    }
                                } label: {
                                    Label("Collect", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                        }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func statisticsSection(_ stats: TreasureStatistics) -> some View {
        Section {
            HStack {
                StatisticView(
                    title: "Total",
                    value: "\(stats.total)",
                    systemImage: "map.fill",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticView(
                    title: "Collected",
                    value: "\(stats.collected)",
                    systemImage: "checkmark.circle.fill",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticView(
                    title: "Remaining",
                    value: "\(stats.uncollected)",
                    systemImage: "questionmark.circle.fill",
                    color: .orange
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("Statistics")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let treasure = treasures[index]
                modelContext.delete(treasure)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Error deleting treasure: \(error)")
            }
        }
    }
    
    private func deleteTreasure(_ treasure: Treasure) {
        withAnimation {
            modelContext.delete(treasure)
            
            do {
                try modelContext.save()
            } catch {
                print("Error deleting treasure: \(error)")
            }
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TreasureListView()
        .modelContainer(for: Treasure.self, inMemory: true)
}