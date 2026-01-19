//
//  SidebarView.swift
//  Knowhere
//
//  Sidebar for category navigation
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var showingNewCategory = false
    @State private var newCategoryName = ""
    
    var body: some View {
        List(selection: $promptStore.selectedCategoryId) {
            Section {
                NavigationLink(value: nil as UUID?) {
                    Label("All Prompts", systemImage: "tray.full.fill")
                }
                .tag(nil as UUID?)
                
                NavigationLink {
                    FavoritesView()
                } label: {
                    Label("Favorites", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
                
                NavigationLink {
                    RecentView()
                } label: {
                    Label("Recent", systemImage: "clock.fill")
                        .foregroundStyle(.cyan)
                }
            } header: {
                Text("Library")
            }
            
            Section {
                ForEach(promptStore.categories) { category in
                    NavigationLink(value: category.id) {
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                        }
                    }
                    .tag(category.id as UUID?)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            promptStore.deleteCategory(category)
                        }
                    }
                }
                
                Button {
                    showingNewCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } header: {
                Text("Categories")
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .background(Color(hex: "#1a1a2e")?.opacity(0.8) ?? .clear)
        .scrollContentBackground(.hidden)
        .alert("New Category", isPresented: $showingNewCategory) {
            TextField("Category name", text: $newCategoryName)
            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
            Button("Add") {
                if !newCategoryName.isEmpty {
                    let category = Category(name: newCategoryName)
                    promptStore.addCategory(category)
                    newCategoryName = ""
                }
            }
        }
    }
}

// MARK: - Favorites View
struct FavoritesView: View {
    @EnvironmentObject var promptStore: PromptStore
    
    var body: some View {
        List {
            ForEach(promptStore.favoritePrompts) { prompt in
                PromptRowView(prompt: prompt, onCopy: {
                    promptStore.copyPrompt(prompt)
                })
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Favorites")
    }
}

// MARK: - Recent View
struct RecentView: View {
    @EnvironmentObject var promptStore: PromptStore
    
    var body: some View {
        List {
            ForEach(promptStore.recentPrompts) { prompt in
                PromptRowView(prompt: prompt, onCopy: {
                    promptStore.copyPrompt(prompt)
                })
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Recent")
    }
}

#Preview {
    SidebarView()
        .environmentObject(PromptStore())
}
