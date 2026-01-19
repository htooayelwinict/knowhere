//
//  Prompt.swift
//  Knowhere
//
//  Data model for AI prompts
//

import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var categoryId: UUID?
    var createdAt: Date
    var lastUsedAt: Date?
    var isFavorite: Bool
    var usageCount: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        categoryId: UUID? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        usageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.usageCount = usageCount
    }
}

// MARK: - Sample Data
extension Prompt {
    static let samples: [Prompt] = [
        Prompt(
            title: "Code Review Request",
            content: "Please review this code and suggest improvements for readability, performance, and best practices:\n\n[paste code here]",
            isFavorite: true
        ),
        Prompt(
            title: "Explain Like I'm 5",
            content: "Explain the following concept in simple terms that a 5-year-old could understand:\n\n[topic]"
        ),
        Prompt(
            title: "Debug Helper",
            content: "I'm encountering the following error. Please help me understand what's causing it and how to fix it:\n\nError: [paste error]\n\nCode: [paste relevant code]"
        ),
        Prompt(
            title: "Summarize Text",
            content: "Please summarize the following text in 3-5 bullet points, capturing the key points:\n\n[paste text]"
        )
    ]
}
