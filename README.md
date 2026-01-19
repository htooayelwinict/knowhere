# Knowhere - AI Prompt Manager

A native macOS app to collect, organize, and quickly access your AI prompts. Built for MacBook Air M1 with SwiftUI.

![Knowhere](https://img.shields.io/badge/Platform-macOS%2013+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

## ✨ Features

- **📚 Prompt Library** - Store and organize your AI prompts with titles, descriptions, and categories
- **🪟 Floating Panel** - A small overlay window that stays on top of other apps for quick access
- **📋 Quick Copy** - One-click to copy any prompt to clipboard
- **🔍 Search** - Instantly filter prompts by title or content
- **🏷️ Categories** - Organize prompts into custom categories (Coding, Writing, Research, etc.)
- **⌨️ Keyboard Shortcut** - Global hotkey `⌥ Space` (Option + Space) to show/hide the floating panel

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later

### Building the App

1. **Open in Xcode**
   ```bash
   cd /Users/lewisae/Documents/VSCode/Mac-App/knowhere/Knowhere
   open Knowhere.xcodeproj
   ```
   
   Or double-click `Knowhere.xcodeproj` in Finder.

2. **Build and Run**
   - Press `⌘ R` (Command + R) in Xcode
   - Or select **Product → Run** from the menu

3. **Trust the App** (First Run)
   - macOS may ask you to allow the app in System Preferences → Privacy & Security
   - For the global hotkey to work, grant Accessibility permissions when prompted

## 📖 How to Use

### Main Window
- **Sidebar**: Navigate between All Prompts, Favorites, Recent, and Categories
- **Prompt List**: Browse and search your prompts
- **Detail View**: View the full prompt content and copy to clipboard

### Floating Panel
- Press `⌥ Space` (Option + Space) from anywhere to toggle the floating panel
- Search for prompts and click to copy instantly
- Click on a prompt to copy it to your clipboard

### Managing Prompts
- **Add Prompt**: Click the `+` button or press `⌘ N`
- **Edit Prompt**: Right-click on a prompt and select "Edit"
- **Delete Prompt**: Right-click and select "Delete"
- **Favorite**: Right-click and toggle "Add to Favorites"

### Categories
- Default categories include: Coding, Writing, Research, Creative, Business
- Add new categories from the sidebar
- Assign categories when creating or editing prompts

## 📁 Project Structure

```
Knowhere/
├── KnowhereApp.swift          # Main app entry point
├── Models/
│   ├── Prompt.swift           # Prompt data model
│   └── Category.swift         # Category data model
├── Views/
│   ├── ContentView.swift      # Main window view
│   ├── SidebarView.swift      # Category sidebar
│   ├── PromptListView.swift   # Prompt list with search
│   ├── PromptDetailView.swift # Full prompt view
│   ├── PromptEditorView.swift # Add/edit prompt form
│   ├── FloatingPanelView.swift # Overlay panel UI
│   └── SettingsView.swift     # App settings
├── Services/
│   ├── PromptStore.swift      # Data management & persistence
│   └── FloatingPanelController.swift # Floating window controller
└── Resources/
    └── Assets.xcassets/       # App icons and colors
```

## 💾 Data Storage

Your prompts and categories are automatically saved to:
```
~/Library/Application Support/Knowhere/
├── prompts.json
└── categories.json
```

You can backup these files to preserve your data.

## 🔧 Configuration

### Settings (Preferences → Settings)
- Enable/disable global keyboard shortcut
- Export/import data for backup

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `⌥ Space` | Toggle floating panel |
| `⌘ N` | New prompt |
| `⌘ ,` | Open settings |

## 📝 License

MIT License - Feel free to use and modify!

---

Made with ❤️ for productive AI users
