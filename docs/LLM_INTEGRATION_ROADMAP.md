# Knowhere 2.0: LLM Integration Roadmap

> Transforming Knowhere from a Prompt Manager into an AI Command Center

**Document Version:** 1.0  
**Date:** January 20, 2026  
**Status:** Draft Proposal

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Vision: AI Command Center](#vision-ai-command-center)
4. [Feature Specifications](#feature-specifications)
5. [Architecture Design](#architecture-design)
6. [Implementation Phases](#implementation-phases)
7. [Technical Considerations](#technical-considerations)
8. [Competitive Analysis](#competitive-analysis)

---

## Executive Summary

**Knowhere** is currently a beautifully crafted native macOS AI Prompt Manager with an innovative AssistiveTouch-style floating bubble interface. This document outlines a strategic roadmap to evolve Knowhere into a full-fledged **AI Command Center** by integrating LLM capabilities, agentic workflows, and intelligent automation.

### The Transformation

```
Current:  Prompt → Copy → Paste to ChatGPT → Response
Future:   Prompt → Execute → Response appears in Knowhere
```

### Key Value Propositions

- **Native macOS Experience**: Fast, beautiful, system-integrated
- **Prompt-First Design**: Library of reusable workflows
- **Multi-Provider Support**: Not locked to one AI company
- **Privacy-Friendly**: Local model support via Ollama
- **Always Accessible**: AssistiveTouch paradigm
- **Agentic Capabilities**: Not just chat, but automated workflows

---

## Current State Analysis

### Existing Architecture

| Component | Description |
|-----------|-------------|
| `KnowhereApp.swift` | Main app entry, window management, global hotkeys |
| `PromptStore.swift` | Data persistence layer for prompts and categories |
| `FloatingBubbleController.swift` | AssistiveTouch-style floating bubble |
| `FloatingPanelController.swift` | Floating panel window management |
| `RadialMenuBubbleView.swift` | Radial menu with location-aware positioning |

### Current Data Models

```swift
struct Prompt: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var categoryId: UUID?
    var createdAt: Date
    var lastUsedAt: Date?
    var isFavorite: Bool
    var usageCount: Int
}

struct Category: Identifiable, Codable {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
}
```

### Strengths to Build Upon

- ✅ Solid SwiftUI + AppKit hybrid architecture
- ✅ Unique floating bubble UX paradigm
- ✅ Clean separation of concerns
- ✅ JSON-based persistence (easily extensible)
- ✅ Global hotkey support
- ✅ Beautiful glassmorphism UI

---

## Vision: AI Command Center

### Core Concept

Knowhere becomes the **"AI bubble that lives on your desktop"** — a persistent, always-accessible interface to AI that:

1. **Stores** your best prompts and workflows
2. **Executes** prompts directly against multiple LLM providers
3. **Captures** context from your system (clipboard, selections, active apps)
4. **Automates** multi-step AI workflows (agents)
5. **Learns** from your knowledge base (RAG)

### User Experience Vision

```
┌─────────────────────────────────────────────────────────────┐
│  User working in VS Code                                    │
│                                                             │
│  1. Selects buggy code                                      │
│  2. Clicks floating bubble                                  │
│  3. Taps "Debug Helper" from radial menu                   │
│  4. Knowhere auto-injects selected code into prompt         │
│  5. Executes against GPT-4o                                 │
│  6. Response streams into floating panel                    │
│  7. One-click to copy fix or apply suggestion              │
│                                                             │
│  Total time: ~5 seconds vs ~30 seconds with browser        │
└─────────────────────────────────────────────────────────────┘
```

---

## Feature Specifications

### Feature 1: Direct LLM Execution Layer

**Priority:** 🔴 Critical (Phase 1)

#### Description
Enable prompts to be executed directly against LLM APIs, with responses displayed in Knowhere.

#### Supported Providers

| Provider | Models | Notes |
|----------|--------|-------|
| OpenAI | GPT-4o, GPT-4-turbo, GPT-3.5-turbo | Primary provider |
| Anthropic | Claude 3.5 Sonnet, Claude 3 Opus | Best for coding |
| Ollama | Llama 3, Mistral, CodeLlama | Local, free, private |
| Groq | Llama 3, Mixtral | Ultra-fast inference |
| Google | Gemini Pro, Gemini Flash | Multi-modal |

#### Extended Prompt Model

```swift
struct Prompt: Identifiable, Codable, Hashable {
    // Existing fields
    var id: UUID
    var title: String
    var content: String
    var categoryId: UUID?
    var createdAt: Date
    var lastUsedAt: Date?
    var isFavorite: Bool
    var usageCount: Int
    
    // NEW: LLM Execution fields
    var preferredProvider: LLMProvider?
    var preferredModel: String?
    var systemPrompt: String?
    var temperature: Double?
    var maxTokens: Int?
    var enableStreaming: Bool
}

enum LLMProvider: String, Codable, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case ollama = "Ollama"
    case groq = "Groq"
    case google = "Google"
}
```

#### New Services

```swift
// Protocol for all LLM providers
protocol LLMService {
    func generate(
        prompt: String,
        systemPrompt: String?,
        model: String,
        temperature: Double,
        maxTokens: Int,
        stream: Bool
    ) async throws -> AsyncThrowingStream<String, Error>
}

// Provider manager
class LLMProviderManager: ObservableObject {
    @Published var activeProvider: LLMProvider = .openai
    @Published var isGenerating: Bool = false
    
    private var providers: [LLMProvider: LLMService] = [:]
    
    func execute(prompt: Prompt, context: ExecutionContext) async throws -> AsyncThrowingStream<String, Error>
}
```

#### UI Changes

- **Prompt Detail View**: Add "Execute" button alongside "Copy"
- **Floating Panel**: Show streaming response with markdown rendering
- **Settings**: API key management with secure Keychain storage

---

### Feature 2: Smart Context Capture

**Priority:** 🟠 High (Phase 2)

#### Description
Automatically capture context from the user's system to enhance prompts.

#### Context Sources

| Source | Method | Usage |
|--------|--------|-------|
| Clipboard | `NSPasteboard.general` | Auto-detect code, URLs, text |
| Selected Text | Accessibility API | Grab selections from any app |
| Active App | `NSWorkspace.shared.frontmostApplication` | Adjust behavior per app |
| Screenshots | `CGWindowListCreateImage` | Vision model input |
| File Contents | File picker or drag-drop | Include in prompts |

#### Variable System

```swift
enum PromptVariable: String, CaseIterable {
    case clipboard = "{{clipboard}}"
    case selectedText = "{{selected_text}}"
    case activeApp = "{{active_app}}"
    case currentDate = "{{date}}"
    case currentTime = "{{time}}"
    case fileName = "{{file_name}}"
    case fileContent = "{{file_content}}"
}

class ContextResolver {
    func resolve(_ prompt: String) async -> String {
        // Replace all variables with actual values
    }
}
```

#### Smart Placeholder Detection

```swift
// Auto-detect patterns like [paste code here], <your text>, etc.
class PlaceholderDetector {
    static let patterns = [
        "\\[.*?\\]",           // [paste code here]
        "<.*?>",               // <your text>
        "\\{\\{.*?\\}\\}",     // {{variable}}
    ]
    
    func detectAndFill(_ content: String, context: ExecutionContext) -> String
}
```

---

### Feature 3: Agentic Workflows

**Priority:** 🟡 Medium (Phase 3)

#### Description
Create multi-step AI workflows that can use tools and chain prompts together.

#### Workflow Model

```swift
struct AgentWorkflow: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var steps: [WorkflowStep]
    var icon: String
    var colorHex: String
}

struct WorkflowStep: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: StepType
    var promptId: UUID?           // Reference to existing prompt
    var inlinePrompt: String?     // Or define inline
    var toolsEnabled: [AgentTool]
    var inputMapping: [String: String]  // Map previous outputs
    var condition: StepCondition?       // Conditional execution
}

enum StepType: String, Codable {
    case llmCall          // Call an LLM
    case toolExecution    // Run a tool
    case userInput        // Wait for user input
    case conditional      // Branch based on condition
}
```

#### Built-in Agent Templates

| Template | Steps | Description |
|----------|-------|-------------|
| **Code Review** | Analyze → Suggest → Implement | Full code review pipeline |
| **Research** | Search → Gather → Summarize | Multi-source research |
| **Writing** | Draft → Review → Polish | Writing assistant |
| **Debug** | Analyze → Hypothesize → Verify | Debugging workflow |

#### Workflow Execution Engine

```swift
class WorkflowExecutor: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var stepOutputs: [UUID: String] = [:]
    @Published var status: ExecutionStatus = .idle
    
    func execute(_ workflow: AgentWorkflow, context: ExecutionContext) async throws {
        for (index, step) in workflow.steps.enumerated() {
            currentStep = index
            let output = try await executeStep(step, previousOutputs: stepOutputs)
            stepOutputs[step.id] = output
        }
    }
}
```

---

### Feature 4: Tool Integrations

**Priority:** 🟡 Medium (Phase 3)

#### Description
Provide tools that agents can use during workflow execution.

#### Available Tools

```swift
enum AgentTool: String, Codable, CaseIterable {
    case clipboardRead = "clipboard_read"
    case clipboardWrite = "clipboard_write"
    case webSearch = "web_search"
    case webFetch = "web_fetch"
    case fileRead = "file_read"
    case fileWrite = "file_write"
    case shellExecute = "shell_execute"
    case screenshot = "screenshot"
    case notification = "notification"
}

protocol ToolExecutable {
    var name: String { get }
    var description: String { get }
    var parameters: [ToolParameter] { get }
    
    func execute(params: [String: Any]) async throws -> ToolResult
}

struct ToolResult {
    let success: Bool
    let output: String
    let data: Data?
}
```

#### Tool Implementations

```swift
class WebSearchTool: ToolExecutable {
    let name = "web_search"
    let description = "Search the web using DuckDuckGo"
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        guard let query = params["query"] as? String else {
            throw ToolError.missingParameter("query")
        }
        // Perform search and return results
    }
}

class ShellExecuteTool: ToolExecutable {
    let name = "shell_execute"
    let description = "Execute a shell command"
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        guard let command = params["command"] as? String else {
            throw ToolError.missingParameter("command")
        }
        // Execute with sandboxing and timeout
    }
}
```

---

### Feature 5: RAG Knowledge Base

**Priority:** 🟢 Lower (Phase 4)

#### Description
Allow users to import documents and use them as context for AI queries.

#### Knowledge Base Model

```swift
struct KnowledgeDocument: Identifiable, Codable {
    var id: UUID
    var name: String
    var sourceURL: URL?
    var content: String
    var embedding: [Float]?  // Vector embedding
    var metadata: DocumentMetadata
    var createdAt: Date
}

struct DocumentMetadata: Codable {
    var fileType: String
    var wordCount: Int
    var language: String?
    var tags: [String]
}
```

#### Vector Storage

```swift
class VectorStore {
    private let index: FaissIndex  // Or use SQLite with vector extension
    
    func addDocument(_ document: KnowledgeDocument) async throws
    func search(query: String, topK: Int) async throws -> [KnowledgeDocument]
    func delete(_ documentId: UUID) async throws
}

class EmbeddingService {
    func embed(_ text: String) async throws -> [Float] {
        // Use OpenAI embeddings or local model
    }
}
```

#### RAG Pipeline

```swift
class RAGPipeline {
    let vectorStore: VectorStore
    let embeddingService: EmbeddingService
    let llmService: LLMService
    
    func query(_ question: String, topK: Int = 5) async throws -> String {
        // 1. Embed the question
        let queryEmbedding = try await embeddingService.embed(question)
        
        // 2. Find relevant documents
        let relevantDocs = try await vectorStore.search(query: question, topK: topK)
        
        // 3. Build context-enhanced prompt
        let context = relevantDocs.map { $0.content }.joined(separator: "\n\n")
        let enhancedPrompt = """
        Context:
        \(context)
        
        Question: \(question)
        
        Answer based on the context provided:
        """
        
        // 4. Generate response
        return try await llmService.generate(prompt: enhancedPrompt, ...)
    }
}
```

---

### Feature 6: Enhanced UI Components

**Priority:** 🟠 High (Ongoing)

#### New Radial Menu Actions

```swift
enum RadialAction: String, CaseIterable, Identifiable {
    // Existing
    case prompts = "Prompts"
    case favorites = "Favorites"
    case recent = "Recent"
    case newPrompt = "New"
    case settings = "Settings"
    case openApp = "Open"
    
    // NEW
    case execute = "Execute"       // Run last/selected prompt
    case quickChat = "Chat"        // Open mini chat interface
    case screenshot = "Capture"    // Screenshot + analyze
    case voiceInput = "Voice"      // Speech-to-text
    case workflows = "Workflows"   // Agent workflows
}
```

#### Response Panel View

```swift
struct ResponsePanelView: View {
    @ObservedObject var executor: LLMProviderManager
    @State private var response: String = ""
    
    var body: some View {
        VStack {
            // Model selector
            ModelPicker(selection: $executor.activeModel)
            
            // Streaming response with markdown
            ScrollView {
                MarkdownView(content: response)
            }
            
            // Action buttons
            HStack {
                Button("Copy") { copyToClipboard(response) }
                Button("Save as Prompt") { saveAsPrompt(response) }
                Button("Continue") { continueConversation() }
            }
        }
    }
}
```

#### Bubble Status Indicators

```swift
struct BubbleStatusView: View {
    let status: BubbleStatus
    
    enum BubbleStatus {
        case idle
        case thinking      // Pulsing animation
        case streaming     // Progress indicator
        case error         // Red tint
        case success       // Green flash
    }
    
    var body: some View {
        ZStack {
            // Base bubble
            Circle()
                .fill(statusColor)
            
            // Status overlay
            statusOverlay
        }
        .animation(.easeInOut, value: status)
    }
}
```

---

## Architecture Design

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        KNOWHERE 2.0                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────── UI LAYER ──────────────────────┐         │
│  │                                                    │         │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │         │
│  │  │ Floating │  │ Floating │  │    Main      │    │         │
│  │  │  Bubble  │  │  Panel   │  │   Window     │    │         │
│  │  │ + Radial │  │+ Response│  │ + Workflow   │    │         │
│  │  │   Menu   │  │  Stream  │  │   Builder    │    │         │
│  │  └──────────┘  └──────────┘  └──────────────┘    │         │
│  │                                                    │         │
│  └────────────────────────────────────────────────────┘         │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────── INTELLIGENCE LAYER ────────────────┐         │
│  │                                                    │         │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │         │
│  │  │   LLM    │  │  Agent   │  │     RAG      │    │         │
│  │  │ Provider │  │ Executor │  │   Pipeline   │    │         │
│  │  │ Manager  │  │          │  │              │    │         │
│  │  └──────────┘  └──────────┘  └──────────────┘    │         │
│  │                                                    │         │
│  └────────────────────────────────────────────────────┘         │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────── TOOL LAYER ────────────────────┐         │
│  │                                                    │         │
│  │  ┌────┐ ┌────┐ ┌─────┐ ┌─────┐ ┌────┐ ┌──────┐  │         │
│  │  │Web │ │File│ │Clip │ │Shell│ │ Cal│ │Vision│  │         │
│  │  │Srch│ │ IO │ │board│ │ Exec│ │endr│ │      │  │         │
│  │  └────┘ └────┘ └─────┘ └─────┘ └────┘ └──────┘  │         │
│  │                                                    │         │
│  └────────────────────────────────────────────────────┘         │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────── DATA LAYER ────────────────────┐         │
│  │                                                    │         │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │         │
│  │  │  Prompt  │  │ Keychain │  │    Vector    │    │         │
│  │  │  Store   │  │(API Keys)│  │    Store     │    │         │
│  │  │  (JSON)  │  │          │  │   (SQLite)   │    │         │
│  │  └──────────┘  └──────────┘  └──────────────┘    │         │
│  │                                                    │         │
│  └────────────────────────────────────────────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Directory Structure (Proposed)

```
Knowhere/
├── KnowhereApp.swift
├── Models/
│   ├── Prompt.swift
│   ├── Category.swift
│   ├── AgentWorkflow.swift          # NEW
│   ├── KnowledgeDocument.swift      # NEW
│   └── LLMConfiguration.swift       # NEW
├── Services/
│   ├── PromptStore.swift
│   ├── FloatingBubbleController.swift
│   ├── FloatingPanelController.swift
│   ├── LLM/                         # NEW
│   │   ├── LLMProviderManager.swift
│   │   ├── OpenAIService.swift
│   │   ├── AnthropicService.swift
│   │   ├── OllamaService.swift
│   │   └── GroqService.swift
│   ├── Agents/                      # NEW
│   │   ├── WorkflowExecutor.swift
│   │   ├── ContextResolver.swift
│   │   └── ToolExecutor.swift
│   ├── Tools/                       # NEW
│   │   ├── WebSearchTool.swift
│   │   ├── FileTool.swift
│   │   ├── ClipboardTool.swift
│   │   └── ShellTool.swift
│   └── RAG/                         # NEW
│       ├── VectorStore.swift
│       ├── EmbeddingService.swift
│       └── RAGPipeline.swift
├── Views/
│   ├── ContentView.swift
│   ├── PromptListView.swift
│   ├── PromptDetailView.swift
│   ├── PromptEditorView.swift
│   ├── RadialMenuBubbleView.swift
│   ├── ResponsePanelView.swift      # NEW
│   ├── WorkflowBuilderView.swift    # NEW
│   ├── WorkflowExecutionView.swift  # NEW
│   ├── KnowledgeBaseView.swift      # NEW
│   └── APISettingsView.swift        # NEW
└── Resources/
    └── Assets.xcassets/
```

---

## Implementation Phases

### Phase 1: LLM Execution Foundation (2-3 weeks)

**Goal:** Enable direct prompt execution against LLM APIs

| Task | Priority | Effort |
|------|----------|--------|
| Create `LLMService` protocol | 🔴 | 2h |
| Implement `OpenAIService` | 🔴 | 4h |
| Implement `AnthropicService` | 🔴 | 4h |
| Create `LLMProviderManager` | 🔴 | 3h |
| Add Keychain API key storage | 🔴 | 3h |
| Extend `Prompt` model with LLM fields | 🔴 | 2h |
| Add "Execute" button to `PromptDetailView` | 🔴 | 2h |
| Create `ResponsePanelView` with streaming | 🔴 | 6h |
| Add API settings to `SettingsView` | 🔴 | 4h |
| Testing and refinement | 🟠 | 8h |

**Deliverables:**
- Users can execute prompts directly from Knowhere
- Responses stream in real-time
- Support for OpenAI and Anthropic

---

### Phase 2: Context & Variables (1-2 weeks)

**Goal:** Smart context capture and variable injection

| Task | Priority | Effort |
|------|----------|--------|
| Create `ContextResolver` service | 🟠 | 4h |
| Implement clipboard variable | 🟠 | 2h |
| Implement selected text capture (Accessibility) | 🟠 | 6h |
| Create variable picker UI | 🟠 | 3h |
| Add smart placeholder detection | 🟠 | 4h |
| Update `PromptEditorView` with variables | 🟠 | 3h |
| Testing and refinement | 🟠 | 4h |

**Deliverables:**
- Variables like `{{clipboard}}` auto-resolve
- Selected text from any app can be captured
- Smart placeholder filling

---

### Phase 3: Local Models & Multi-Provider (1-2 weeks)

**Goal:** Ollama support and provider switching

| Task | Priority | Effort |
|------|----------|--------|
| Implement `OllamaService` | 🟠 | 4h |
| Implement `GroqService` | 🟡 | 3h |
| Create model discovery for Ollama | 🟠 | 3h |
| Add model picker to execution UI | 🟠 | 4h |
| Per-prompt model preferences | 🟠 | 3h |
| Offline detection and fallback | 🟡 | 3h |
| Testing with various models | 🟠 | 4h |

**Deliverables:**
- Full Ollama integration (local Llama 3, etc.)
- Easy provider/model switching
- Offline-capable with local models

---

### Phase 4: Agent Workflows (2-3 weeks)

**Goal:** Multi-step automated AI workflows

| Task | Priority | Effort |
|------|----------|--------|
| Create `AgentWorkflow` model | 🟡 | 3h |
| Create `WorkflowExecutor` | 🟡 | 8h |
| Implement built-in tools | 🟡 | 8h |
| Create `WorkflowBuilderView` | 🟡 | 8h |
| Create `WorkflowExecutionView` | 🟡 | 6h |
| Add workflow templates | 🟡 | 4h |
| Testing complex workflows | 🟡 | 6h |

**Deliverables:**
- Visual workflow builder
- Built-in tool integrations
- Pre-made workflow templates

---

### Phase 5: RAG Knowledge Base (2-3 weeks)

**Goal:** Personal knowledge base with semantic search

| Task | Priority | Effort |
|------|----------|--------|
| Create `KnowledgeDocument` model | 🟢 | 2h |
| Implement `EmbeddingService` | 🟢 | 4h |
| Implement `VectorStore` | 🟢 | 8h |
| Create `RAGPipeline` | 🟢 | 6h |
| Create `KnowledgeBaseView` | 🟢 | 6h |
| Document import (PDF, MD, TXT) | 🟢 | 6h |
| Integration with prompt execution | 🟢 | 4h |
| Testing and refinement | 🟢 | 6h |

**Deliverables:**
- Import and index documents
- Semantic search across knowledge base
- RAG-enhanced prompt responses

---

## Technical Considerations

### API Key Security

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    func save(apiKey: String, for provider: LLMProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "knowhere-\(provider.rawValue)",
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrieve(for provider: LLMProvider) throws -> String? {
        // Implementation
    }
}
```

### Streaming Response Handling

```swift
class StreamingResponseHandler: ObservableObject {
    @Published var content: String = ""
    @Published var isStreaming: Bool = false
    @Published var error: Error?
    
    func handle(_ stream: AsyncThrowingStream<String, Error>) async {
        isStreaming = true
        defer { isStreaming = false }
        
        do {
            for try await chunk in stream {
                await MainActor.run {
                    content += chunk
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
}
```

### Accessibility API for Text Selection

```swift
import ApplicationServices

class AccessibilityService {
    func getSelectedText() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElement: AnyObject?
        let focusedError = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard focusedError == .success,
              let element = focusedElement else { return nil }
        
        var selectedText: AnyObject?
        let textError = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        guard textError == .success else { return nil }
        return selectedText as? String
    }
}
```

### Sandboxing Considerations

For Mac App Store distribution, consider:

| Feature | Sandbox Impact | Solution |
|---------|---------------|----------|
| Clipboard | ✅ Allowed | Native API |
| Selected Text | ⚠️ Requires entitlement | Accessibility permission |
| File Access | ⚠️ Limited | User-selected files only |
| Shell Execute | ❌ Blocked | Remove or use XPC |
| Network | ✅ Allowed | Standard networking |

---

## Competitive Analysis

### Market Landscape

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **ChatGPT** | Feature-rich, GPT-4 | Web-only, context switching |
| **Claude** | Best for coding | Web-only, no macOS integration |
| **Raycast AI** | Native, fast | Subscription, not prompt-focused |
| **Alfred + GPT** | Keyboard-driven | Complex setup, no UI |
| **MacGPT** | Menu bar access | Basic, single provider |

### Knowhere 2.0 Differentiation

| Advantage | Description |
|-----------|-------------|
| **Prompt Library** | Curated, categorized, reusable prompts |
| **AssistiveTouch UX** | Unique, always-accessible bubble |
| **Multi-Provider** | Not locked to one AI company |
| **Local Models** | Privacy-first with Ollama |
| **Agents** | Multi-step workflows, not just chat |
| **Native macOS** | Fast, beautiful, system-integrated |

### Target Users

1. **Developers**: Quick code review, debugging, documentation
2. **Writers**: Content creation, editing, research
3. **Researchers**: Literature review, summarization
4. **Knowledge Workers**: Email drafting, meeting prep
5. **Power Users**: Custom workflows, automation

---

## Appendix A: API Reference Sketches

### OpenAI Service

```swift
class OpenAIService: LLMService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    func generate(
        prompt: String,
        systemPrompt: String?,
        model: String,
        temperature: Double,
        maxTokens: Int,
        stream: Bool
    ) async throws -> AsyncThrowingStream<String, Error> {
        
        let messages = buildMessages(prompt: prompt, systemPrompt: systemPrompt)
        
        let request = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: stream
        )
        
        return try await streamRequest(request)
    }
}
```

### Anthropic Service

```swift
class AnthropicService: LLMService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1"
    
    func generate(
        prompt: String,
        systemPrompt: String?,
        model: String,
        temperature: Double,
        maxTokens: Int,
        stream: Bool
    ) async throws -> AsyncThrowingStream<String, Error> {
        
        let request = MessageRequest(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: [.init(role: "user", content: prompt)],
            stream: stream
        )
        
        return try await streamRequest(request)
    }
}
```

---

## Appendix B: UI Mockup Descriptions

### Enhanced Floating Panel

```
┌────────────────────────────────────────┐
│  ⚙️ GPT-4o  ▼    │  ⏹ Stop  │  📋 Copy │
├────────────────────────────────────────┤
│                                        │
│  ## Response                           │
│                                        │
│  Here's the analysis of your code:     │
│                                        │
│  1. **Issue Found**: The loop at       │
│     line 42 has an off-by-one error    │
│                                        │
│  2. **Suggestion**: Change `<=` to `<` │
│                                        │
│  ```swift                              │
│  for i in 0..<array.count {            │
│      // Fixed loop                     │
│  }                                     │
│  ```                                   │
│                                        │
│  ████████████░░░░░░░░░░ 60%            │
│                                        │
├────────────────────────────────────────┤
│  💬 Continue conversation...           │
└────────────────────────────────────────┘
```

### Workflow Builder

```
┌────────────────────────────────────────┐
│  📋 Code Review Workflow               │
├────────────────────────────────────────┤
│                                        │
│  ┌──────┐     ┌──────┐     ┌──────┐   │
│  │ Step │ ──▶ │ Step │ ──▶ │ Step │   │
│  │  1   │     │  2   │     │  3   │   │
│  └──────┘     └──────┘     └──────┘   │
│  Analyze      Suggest      Implement   │
│                                        │
│  ─────────────────────────────────────│
│  Step 2: Suggest Improvements          │
│  ┌─────────────────────────────────┐  │
│  │ Prompt: Code Review             ▼│  │
│  │ Model: Claude 3.5 Sonnet        ▼│  │
│  │ Tools: ☑ clipboard  ☐ web_search │  │
│  │ Input: {{step_1_output}}         │  │
│  └─────────────────────────────────┘  │
│                                        │
│  [+ Add Step]           [▶ Test Run]  │
└────────────────────────────────────────┘
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-20 | AI Assistant | Initial draft |

---

*This document is a living specification and will be updated as development progresses.*
