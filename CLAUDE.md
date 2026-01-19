# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Knowhere - native macOS app (Swift 5.9+, macOS 13+) for managing AI prompts. Built with SwiftUI.

## Build & Run

```bash
# Open in Xcode (recommended)
open Knowhere/Knowhere.xcodeproj

# Then press ⌘ R in Xcode

# Or build from command line
xcodebuild -project Knowhere/Knowhere.xcodeproj -scheme Knowhere build
```

**Note**: No test or lint commands configured. Add tests to `KnowhereTests/` target if needed.

## Architecture

**Entry Point**: [KnowhereApp.swift](Knowhere/Knowhere/KnowhereApp.swift) - SwiftUI App with `@NSApplicationDelegateAdaptor(AppDelegate.self)` for global hotkey handling

**Data Layer**: [PromptStore](Knowhere/Services/PromptStore.swift) - `@ObservableObject` singleton managing prompts/categories. Persists to JSON in `~/Library/Application Support/Knowhere/`. Provides computed properties: `filteredPrompts`, `recentPrompts`, `favoritePrompts`.

**UI Modes** (3 separate window controllers):
1. **Main Window** - ContentView with sidebar navigation (All, Favorites, Recent, Categories)
2. **Floating Panel** (⌥ Space) - [FloatingPanelController](Knowhere/Services/FloatingPanelController.swift) - NSPanel overlay
3. **Floating Bubble** (⌥ B) - [FloatingBubbleController](Knowhere/Services/FloatingBubbleController.swift) - AssistiveTouch-style draggable bubble with radial menu

**Models**: [Prompt](Knowhere/Models/Prompt.swift) (id, title, content, categoryId, timestamps, isFavorite, usageCount), [Category](Knowhere/Models/Category.swift)

**Communication**: Uses `NotificationCenter.default.post(name: .newPrompt, object: nil)` pattern for cross-component communication. Notification names defined in [KnowhereApp.swift:105-108](Knowhere/Knowhere/KnowhereApp.swift#L105-L108)

**Hotkey Registration**: [KnowhereApp.swift:67-93](Knowhere/Knowhere/KnowhereApp.swift#L67-L93) - `NSEvent.addLocalMonitorForEvents` + `addGlobalMonitorForEvents`. Global hotkeys require Accessibility permissions.

## Key Files

- [KnowhereApp.swift](Knowhere/Knowhere/KnowhereApp.swift) - App entry, hotkey setup, notification names, ⌘N menu command
- [PromptStore.swift](Knowhere/Services/PromptStore.swift) - All CRUD operations, search/filter, JSON persistence, clipboard integration
- [FloatingBubbleController.swift](Knowhere/Services/FloatingBubbleController.swift) - Bubble, radial menu, prompt submenu window management
- [FloatingPanelController.swift](Knowhere/Services/FloatingPanelController.swift) - Floating panel overlay
- [Views/](Knowhere/Knowhere/Views/) - SwiftUI views: ContentView, SidebarView, PromptListView, PromptDetailView, PromptEditorView, SettingsView, FloatingPanelView

## Data Storage

Prompts stored as JSON in `~/Library/Application Support/Knowhere/prompts.json` and `categories.json`

## Entitlements

App sandbox disabled ([Knowhere.entitlements](Knowhere/Knowhere/Knowhere.entitlements)) - Required for global hotkeys and file system access
