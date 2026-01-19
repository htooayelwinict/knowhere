//
//  PromptStore.swift
//  Knowhere
//
//  Manages prompts and categories with local persistence
//

import Foundation
import SwiftUI
import Combine

class PromptStore: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var selectedCategoryId: UUID?
    
    private let promptsKey = "knowhere_prompts"
    private let categoriesKey = "knowhere_categories"
    
    private var saveDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let knowhereDir = appSupport.appendingPathComponent("Knowhere", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: knowhereDir.path) {
            try? FileManager.default.createDirectory(at: knowhereDir, withIntermediateDirectories: true)
        }
        
        return knowhereDir
    }
    
    private var promptsFile: URL {
        saveDir.appendingPathComponent("prompts.json")
    }
    
    private var categoriesFile: URL {
        saveDir.appendingPathComponent("categories.json")
    }
    
    init() {
        loadData()
        
        // If no data, add sample data
        if prompts.isEmpty {
            prompts = Prompt.samples
        }
        if categories.isEmpty {
            categories = Category.defaults
        }
    }
    
    // MARK: - Filtered Prompts
    var filteredPrompts: [Prompt] {
        var result = prompts
        
        // Filter by category
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.categoryId == categoryId }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
                prompt.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.createdAt > $1.createdAt }
    }
    
    var recentPrompts: [Prompt] {
        prompts
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }
    
    var favoritePrompts: [Prompt] {
        prompts.filter { $0.isFavorite }
    }
    
    // MARK: - CRUD Operations
    func addPrompt(_ prompt: Prompt) {
        prompts.append(prompt)
        saveData()
    }
    
    func updatePrompt(_ prompt: Prompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index] = prompt
            saveData()
        }
    }
    
    func deletePrompt(_ prompt: Prompt) {
        prompts.removeAll { $0.id == prompt.id }
        saveData()
    }
    
    func deletePrompts(at offsets: IndexSet) {
        let promptsToDelete = offsets.map { filteredPrompts[$0] }
        for prompt in promptsToDelete {
            prompts.removeAll { $0.id == prompt.id }
        }
        saveData()
    }
    
    func copyPrompt(_ prompt: Prompt) {
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt.content, forType: .string)
        
        // Update usage stats
        if var updatedPrompt = prompts.first(where: { $0.id == prompt.id }) {
            updatedPrompt.lastUsedAt = Date()
            updatedPrompt.usageCount += 1
            updatePrompt(updatedPrompt)
        }
    }
    
    func toggleFavorite(_ prompt: Prompt) {
        if var updatedPrompt = prompts.first(where: { $0.id == prompt.id }) {
            updatedPrompt.isFavorite.toggle()
            updatePrompt(updatedPrompt)
        }
    }
    
    // MARK: - Category Operations
    func addCategory(_ category: Category) {
        categories.append(category)
        saveData()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveData()
        }
    }
    
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        // Remove category from prompts
        for i in prompts.indices {
            if prompts[i].categoryId == category.id {
                prompts[i].categoryId = nil
            }
        }
        saveData()
    }
    
    func category(for id: UUID?) -> Category? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }
    
    // MARK: - Persistence
    private func loadData() {
        // Load prompts
        if let data = try? Data(contentsOf: promptsFile),
           let decoded = try? JSONDecoder().decode([Prompt].self, from: data) {
            prompts = decoded
        }
        
        // Load categories
        if let data = try? Data(contentsOf: categoriesFile),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        }
    }
    
    private func saveData() {
        // Save prompts
        if let data = try? JSONEncoder().encode(prompts) {
            try? data.write(to: promptsFile)
        }
        
        // Save categories
        if let data = try? JSONEncoder().encode(categories) {
            try? data.write(to: categoriesFile)
        }
    }
}
