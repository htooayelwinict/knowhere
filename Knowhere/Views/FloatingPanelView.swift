//
//  FloatingPanelView.swift
//  Knowhere
//
//  The always-on-top floating panel for quick prompt access
//

import SwiftUI

enum PromptFilter {
    case all
    case favorites
    case recent
}

struct FloatingPanelView: View {
    @ObservedObject var promptStore: PromptStore
    var onClose: () -> Void

    @State private var searchText = ""
    @State private var showCopiedId: UUID?
    @State private var activeFilter: PromptFilter = .all

    var filteredPrompts: [Prompt] {
        var base: [Prompt]

        // Apply filter
        switch activeFilter {
        case .all:
            base = promptStore.prompts
        case .favorites:
            base = promptStore.favoritePrompts
        case .recent:
            base = promptStore.recentPrompts
        }

        // Apply search
        if searchText.isEmpty {
            return Array(base.prefix(10))
        }
        return base.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(searchText) ||
            prompt.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Knowhere")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("⌥ Space")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(hex: "#1a1a2e") ?? .clear)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search prompts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            
            Divider()
            
            // Quick actions
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "star.fill",
                    label: "Favorites",
                    color: .yellow,
                    isActive: activeFilter == .favorites
                ) {
                    activeFilter = activeFilter == .favorites ? .all : .favorites
                    searchText = ""
                }

                QuickActionButton(
                    icon: "clock.fill",
                    label: "Recent",
                    color: .cyan,
                    isActive: activeFilter == .recent
                ) {
                    activeFilter = activeFilter == .recent ? .all : .recent
                    searchText = ""
                }
            }
            .padding(12)
            
            Divider()
            
            // Prompt list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredPrompts) { prompt in
                        FloatingPromptRow(
                            prompt: prompt,
                            showCopied: showCopiedId == prompt.id
                        ) {
                            copyPrompt(prompt)
                        }
                    }
                }
                .padding(8)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(promptStore.prompts.count) prompts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "Knowhere" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    onClose()
                } label: {
                    Label("Open App", systemImage: "arrow.up.forward.square")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(hex: "#1a1a2e") ?? .clear)
        }
        .frame(width: 400, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#16213e") ?? .black)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func copyPrompt(_ prompt: Prompt) {
        promptStore.copyPrompt(prompt)
        showCopiedId = prompt.id
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedId = nil
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let isActive: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(isActive ? .white : color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isActive ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isActive
                            ? color
                            : (isHovering ? color.opacity(0.2) : Color.white.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Floating Prompt Row
struct FloatingPromptRow: View {
    let prompt: Prompt
    let showCopied: Bool
    let onCopy: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(prompt.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if prompt.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    Text(prompt.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if showCopied {
                    Label("Copied!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if isHovering {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    FloatingPanelView(promptStore: PromptStore()) {}
        .frame(width: 400, height: 500)
}
