//
//  PromptDetailView.swift
//  Knowhere
//
//  Detailed view of a single prompt
//

import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt
    @EnvironmentObject var promptStore: PromptStore
    @State private var showCopied = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(prompt.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if prompt.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title2)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            if let category = promptStore.category(for: prompt.categoryId) {
                                Label(category.name, systemImage: category.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(category.color)
                            }
                            
                            Label(prompt.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if prompt.usageCount > 0 {
                                Label("\(prompt.usageCount) uses", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Copy button
                    Button {
                        promptStore.copyPrompt(prompt)
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    } label: {
                        Label(
                            showCopied ? "Copied!" : "Copy to Clipboard",
                            systemImage: showCopied ? "checkmark.circle.fill" : "doc.on.doc.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(showCopied ? Color.green : Color.blue)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut, value: showCopied)
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Prompt content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(prompt.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
            }
            .padding(32)
        }
        .background(Color.clear)
    }
}

#Preview {
    PromptDetailView(prompt: Prompt.samples[0])
        .environmentObject(PromptStore())
}
