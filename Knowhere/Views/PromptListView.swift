//
//  PromptListView.swift
//  Knowhere
//
//  List view showing all prompts with search
//

import SwiftUI

struct PromptListView: View {
    @EnvironmentObject var promptStore: PromptStore
    @Binding var selectedPrompt: Prompt?
    var onEdit: (Prompt) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(text: $promptStore.searchText)
                .padding()
            
            // Prompt list
            List(selection: $selectedPrompt) {
                ForEach(promptStore.filteredPrompts) { prompt in
                    PromptRowView(
                        prompt: prompt,
                        onCopy: {
                            promptStore.copyPrompt(prompt)
                        }
                    )
                    .tag(prompt)
                    .contextMenu {
                        Button {
                            promptStore.copyPrompt(prompt)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            promptStore.toggleFavorite(prompt)
                        } label: {
                            Label(
                                prompt.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: prompt.isFavorite ? "star.slash" : "star"
                            )
                        }
                        
                        Divider()
                        
                        Button {
                            onEdit(prompt)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            promptStore.deletePrompt(prompt)
                            if selectedPrompt?.id == prompt.id {
                                selectedPrompt = nil
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    promptStore.deletePrompts(at: offsets)
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .frame(minWidth: 300)
        .background(Color(hex: "#16213e")?.opacity(0.6) ?? .clear)
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search prompts...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Prompt Row
struct PromptRowView: View {
    let prompt: Prompt
    var onCopy: () -> Void
    
    @EnvironmentObject var promptStore: PromptStore
    @State private var isHovering = false
    @State private var showCopied = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Category indicator
            if let category = promptStore.category(for: prompt.categoryId) {
                Circle()
                    .fill(category.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if prompt.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Copy button
            if isHovering || showCopied {
                Button {
                    onCopy()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    Label(
                        showCopied ? "Copied!" : "Copy",
                        systemImage: showCopied ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption)
                    .foregroundStyle(showCopied ? .green : .blue)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    PromptListView(selectedPrompt: .constant(nil), onEdit: { _ in })
        .environmentObject(PromptStore())
}
