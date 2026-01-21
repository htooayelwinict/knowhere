//
//  PromptStore.swift
//  Knowhere
//
//  Manages prompts and categories with local persistence
//

import Foundation
import SwiftUI
import Combine
import os.log

private let logger = Logger(subsystem: "com.knowhere.app", category: "PromptStore")

class PromptStore: ObservableObject {
    // MARK: - Clipboard Security
    private var clipboardClearWorkItem: DispatchWorkItem?
    private let clipboardClearDelay: TimeInterval = 60.0 // 60 seconds
    // MARK: - Singleton
    // Use shared instance to ensure all components use the SAME PromptStore
    static let shared = PromptStore()
    
    @Published var prompts: [Prompt] = []
    @Published var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var selectedCategoryId: UUID?
    
    private let promptsKey = "knowhere_prompts"
    private let categoriesKey = "knowhere_categories"
    
    private var saveDir: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get Application Support directory")
            return nil
        }
        let knowhereDir = appSupport.appendingPathComponent("Knowhere", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: knowhereDir.path) {
            do {
                try FileManager.default.createDirectory(at: knowhereDir, withIntermediateDirectories: true)
                // Set restrictive permissions (owner read/write only)
                try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: knowhereDir.path)
            } catch {
                logger.error("Failed to create save directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        return knowhereDir
    }
    
    private var promptsFile: URL? {
        saveDir?.appendingPathComponent("prompts.json")
    }
    
    private var categoriesFile: URL? {
        saveDir?.appendingPathComponent("categories.json")
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
        // Show recently USED prompts (ones that have been copied)
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
        // Cancel any pending clipboard clear
        clipboardClearWorkItem?.cancel()
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt.content, forType: .string)
        
        // Schedule auto-clear after 60 seconds for security
        let workItem = DispatchWorkItem { [weak self] in
            // Only clear if clipboard still contains prompt content
            if let currentContent = NSPasteboard.general.string(forType: .string),
               currentContent == prompt.content {
                NSPasteboard.general.clearContents()
                logger.info("Clipboard auto-cleared after timeout")
            }
        }
        clipboardClearWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + clipboardClearDelay, execute: workItem)
        
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
        guard let promptsURL = promptsFile else {
            logger.warning("Cannot load prompts: save directory unavailable")
            return
        }
        
        do {
            let data = try Data(contentsOf: promptsURL)
            prompts = try JSONDecoder().decode([Prompt].self, from: data)
            logger.info("Loaded \(self.prompts.count) prompts")
        } catch {
            // File might not exist on first launch - this is expected
            if (error as NSError).domain != NSCocoaErrorDomain || (error as NSError).code != NSFileReadNoSuchFileError {
                logger.error("Failed to load prompts: \(error.localizedDescription)")
            }
        }
        
        // Load categories
        guard let categoriesURL = categoriesFile else {
            logger.warning("Cannot load categories: save directory unavailable")
            return
        }
        
        do {
            let data = try Data(contentsOf: categoriesURL)
            categories = try JSONDecoder().decode([Category].self, from: data)
            logger.info("Loaded \(self.categories.count) categories")
        } catch {
            if (error as NSError).domain != NSCocoaErrorDomain || (error as NSError).code != NSFileReadNoSuchFileError {
                logger.error("Failed to load categories: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveData() {
        // Save prompts
        guard let promptsURL = promptsFile else {
            logger.error("Cannot save prompts: save directory unavailable")
            showSaveError("Unable to access save location")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(prompts)
            try data.write(to: promptsURL, options: .atomic)
            // Set restrictive file permissions (owner read/write only)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: promptsURL.path)
            logger.debug("Saved \(self.prompts.count) prompts")
        } catch {
            logger.error("Failed to save prompts: \(error.localizedDescription)")
            showSaveError("Failed to save prompts: \(error.localizedDescription)")
        }
        
        // Save categories
        guard let categoriesURL = categoriesFile else {
            logger.error("Cannot save categories: save directory unavailable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: categoriesURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: categoriesURL.path)
            logger.debug("Saved \(self.categories.count) categories")
        } catch {
            logger.error("Failed to save categories: \(error.localizedDescription)")
        }
    }
    
    private func showSaveError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
