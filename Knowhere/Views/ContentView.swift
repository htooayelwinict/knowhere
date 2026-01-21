//
//  ContentView.swift
//  Knowhere
//
//  Main window view with sidebar and prompt list
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var selectedPrompt: Prompt?
    @State private var isEditingPrompt = false
    @State private var promptToEdit: Prompt?
    @State private var showingNewPrompt = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } content: {
            PromptListView(
                selectedPrompt: $selectedPrompt,
                onEdit: { prompt in
                    promptToEdit = prompt
                    isEditingPrompt = true
                }
            )
        } detail: {
            if let prompt = selectedPrompt {
                PromptDetailView(prompt: prompt)
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .background(GradientBackground())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewPrompt = true
                } label: {
                    Label("New Prompt", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.toggleFloatingPanel()
                    }
                } label: {
                    Label("Toggle Panel", systemImage: "rectangle.topthird.inset.filled")
                }
                .help("Toggle Floating Panel (⌥ Space)")
            }
        }
        .sheet(isPresented: $showingNewPrompt) {
            PromptEditorView(mode: .new)
        }
        .sheet(isPresented: $isEditingPrompt) {
            if let prompt = promptToEdit {
                PromptEditorView(mode: .edit(prompt))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewPromptSheet)) { _ in
            showingNewPrompt = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showEditPromptSheet)) { notification in
            if let prompt = notification.object as? Prompt {
                promptToEdit = prompt
                isEditingPrompt = true
            }
        }
    }
}

// MARK: - Gradient Background
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#1a1a2e") ?? .black,
                Color(hex: "#16213e") ?? .black,
                Color(hex: "#0f3460") ?? .black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Select a Prompt")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose a prompt from the list to view details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    ContentView()
        .environmentObject(PromptStore())
}
