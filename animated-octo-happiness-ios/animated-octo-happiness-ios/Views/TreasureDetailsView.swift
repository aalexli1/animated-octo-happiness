//
//  TreasureDetailsView.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI

struct TreasureDetailsView: View {
    @ObservedObject var viewModel: TreasureCreationViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, message
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Give your treasure a name")
                        .font(.headline)
                    
                    TextField("Treasure Title", text: $viewModel.treasureTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .message
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Write a message for the finder")
                        .font(.headline)
                    
                    Text("This message will be shown when someone discovers your treasure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $viewModel.treasureMessage)
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .message)
                }
                
                if !viewModel.treasureMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.blue)
                            Text(viewModel.treasureMessage)
                                .lineLimit(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .onAppear {
            focusedField = .title
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}