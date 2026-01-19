//
//  AssistiveTouchMenuView.swift
//  Knowhere
//
//  iPhone AssistiveTouch-style radial menu with glass effects
//

import SwiftUI

// MARK: - Menu Action
enum MenuAction: String, CaseIterable, Identifiable {
    case prompts = "Prompts"
    case favorites = "Favorites"
    case recent = "Recent"
    case newPrompt = "New"
    case settings = "Settings"
    case openApp = "Open App"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .prompts: return "text.bubble.fill"
        case .favorites: return "star.fill"
        case .recent: return "clock.fill"
        case .newPrompt: return "plus.circle.fill"
        case .settings: return "gearshape.fill"
        case .openApp: return "arrow.up.forward.app.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .prompts: return .blue
        case .favorites: return .yellow
        case .recent: return .cyan
        case .newPrompt: return .green
        case .settings: return .gray
        case .openApp: return .purple
        }
    }
}

// MARK: - Main Menu View
struct AssistiveTouchMenuView: View {
    @ObservedObject var promptStore: PromptStore
    var onClose: () -> Void
    var onOpenMainApp: () -> Void
    
    @State private var currentView: MenuViewState = .main
    @State private var isAnimating = false
    
    enum MenuViewState {
        case main
        case prompts
        case favorites
        case recent
    }
    
    var body: some View {
        ZStack {
            switch currentView {
            case .main:
                mainMenuView
                    .transition(.scale.combined(with: .opacity))
            case .prompts:
                promptListView(prompts: promptStore.prompts, title: "All Prompts")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .favorites:
                promptListView(prompts: promptStore.prompts.filter { $0.isFavorite }, title: "Favorites")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .recent:
                promptListView(prompts: promptStore.recentPrompts, title: "Recent")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: 320, height: 380)
        .glassCard(cornerRadius: 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentView)
    }
    
    // MARK: - Main Menu (Radial Layout)
    private var mainMenuView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // App icon placeholder - using ChatGPT-like icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#10a37f") ?? .green, Color(hex: "#1a7f64") ?? .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Knowhere")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Radial Menu Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(MenuAction.allCases) { action in
                    MenuActionButton(action: action) {
                        handleAction(action)
                    }
                }
            }
            .padding(24)
            
            Spacer()
            
            // Footer hint
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Text("Tap an action")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Prompt List View
    private func promptListView(prompts: [Prompt], title: String) -> some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    withAnimation {
                        currentView = .main
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Spacer for balance
                Color.clear
                    .frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            if prompts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No prompts")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(prompts) { prompt in
                            PromptRowButton(prompt: prompt) {
                                promptStore.copyPrompt(prompt)
                                onClose()
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
    
    // MARK: - Action Handler
    private func handleAction(_ action: MenuAction) {
        switch action {
        case .prompts:
            withAnimation {
                currentView = .prompts
            }
        case .favorites:
            withAnimation {
                currentView = .favorites
            }
        case .recent:
            withAnimation {
                currentView = .recent
            }
        case .newPrompt:
            NotificationCenter.default.post(name: .newPrompt, object: nil)
            onOpenMainApp()
            onClose()
        case .settings:
            if let url = URL(string: "knowhere://settings") {
                NSWorkspace.shared.open(url)
            }
            onOpenMainApp()
            onClose()
        case .openApp:
            onOpenMainApp()
            onClose()
        }
    }
}

// MARK: - Menu Action Button
struct MenuActionButton: View {
    let action: MenuAction
    let onTap: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    action.color.opacity(isHovering ? 0.4 : 0.25),
                                    action.color.opacity(isHovering ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    // Border
                    Circle()
                        .stroke(action.color.opacity(isHovering ? 0.6 : 0.3), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    
                    // Icon
                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(action.color)
                }
                .scaleEffect(isPressed ? 0.9 : (isHovering ? 1.1 : 1.0))
                
                Text(action.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Prompt Row Button
struct PromptRowButton: View {
    let prompt: Prompt
    let onCopy: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(prompt.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if prompt.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(prompt.content)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isHovering {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.white.opacity(0.1) : Color.clear)
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

#Preview {
    AssistiveTouchMenuView(
        promptStore: PromptStore(),
        onClose: {},
        onOpenMainApp: {}
    )
    .frame(width: 320, height: 380)
    .preferredColorScheme(.dark)
}
