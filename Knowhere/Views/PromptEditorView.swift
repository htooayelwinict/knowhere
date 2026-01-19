//
//  PromptEditorView.swift
//  Knowhere
//
//  Form for creating and editing prompts
//

import SwiftUI

enum PromptEditorMode {
    case new
    case edit(Prompt)
}

struct PromptEditorView: View {
    @EnvironmentObject var promptStore: PromptStore
    @Environment(\.dismiss) var dismiss
    
    let mode: PromptEditorMode
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var isFavorite: Bool = false
    @FocusState private var isTitleFocused: Bool
    
    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Prompt" : "New Prompt")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(hex: "#1a1a2e") ?? .clear)
            
            Divider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter a title for this prompt", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .focused($isTitleFocused)
                    }
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(promptStore.categories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    
                    // Favorite toggle
                    Toggle(isOn: $isFavorite) {
                        Label("Add to Favorites", systemImage: "star.fill")
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                    
                    // Content field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt Content")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $content)
                            .font(.system(size: 14, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("• Use [placeholder] for parts you want to fill in later")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("• Be specific about the context and desired output")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding()
            }
            
            Divider()
            
            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(isEditing ? "Save Changes" : "Create Prompt") {
                    savePrompt()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command) // Cmd+Enter to save
                .disabled(title.isEmpty || content.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(hex: "#1a1a2e") ?? .clear)
        }
        .frame(width: 500, height: 600)
        .background(Color(hex: "#16213e") ?? .clear)
        .onAppear {
            if case .edit(let prompt) = mode {
                title = prompt.title
                content = prompt.content
                selectedCategoryId = prompt.categoryId
                isFavorite = prompt.isFavorite
            }
            // Delay focus to ensure sheet is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTitleFocused = true
            }
        }
    }
    
    private func savePrompt() {
        if case .edit(let existingPrompt) = mode {
            var updated = existingPrompt
            updated.title = title
            updated.content = content
            updated.categoryId = selectedCategoryId
            updated.isFavorite = isFavorite
            promptStore.updatePrompt(updated)
        } else {
            let newPrompt = Prompt(
                title: title,
                content: content,
                categoryId: selectedCategoryId,
                isFavorite: isFavorite
            )
            promptStore.addPrompt(newPrompt)
        }
    }
}

#Preview {
    PromptEditorView(mode: .new)
        .environmentObject(PromptStore())
}
