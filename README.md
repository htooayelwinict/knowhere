# Knowhere - AI Prompt Manager for macOS

**Knowhere** is a native macOS utility designed to organize, manage, and quickly access your AI prompts. It features a unique **AssistantTouch-style floating bubble** that stays with you, offering instant access to your prompt library from any application.

![Platform](https://img.shields.io/badge/Platform-macOS%2013+-000000.svg?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

## ✨ Key Features

### 🟣 Floating Bubble & Radial Menu
- **AssistiveTouch Style**: A subtle floating bubble that sits on top of your workflow.
- **Smart Radial Menu**: Tapping the bubble expands a beautiful radial menu that **automatically adapts** to its screen position (flips left/right/up/down) to stay on screen.
- **Physics-Based Drag**: Satisfying, zero-lag dragging mechanics.

### 📚 Powerful Prompt Management
- **Library**: Organize your best prompts with title, description, and copy-able content.
- **Categories**: Sort into Coding, Writing, Research, and more.
- **Favorites**: Star your most used prompts for instant access.
- **Search**: Fuzzy search to find exactly what you need in milliseconds.

### ⌨️ Native Workflow
- **Global Hotkey**: Toggle visibility instantly (Default: `Cmd + Shift + K`).
- **Quick Copy**: One-click copying to clipboard.
- **Keyboard Navigation**: Optimized for speed.

## 🛠️ Technology Stack
- **SwiftUI** & **AppKit**
- **Combine** Framework
- **Custom View Modifiers** for Glassmorphism
- **NSEvent** for precise global input handling

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15+

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/htooayelwinict/knowhere.git
   cd knowhere
   ```

2. Open the project in Xcode:
   ```bash
   open Knowhere/Knowhere.xcodeproj
   ```

3. Build and run (Cmd + R).

> **Note**: You may need to grant **Accessibility Permissions** in System Settings for the global hotkey and floating panel features to work correctly.

## 📖 Usage

1. **Launch Knowhere**. The main window will appear.
2. **Add Prompts**: Use the `+` button to create new prompts.
3. **Close Window**: The app continues running in the background.
4. **Floating Bubble**:
   - Drag the bubble anywhere on your screen.
   - Click to open the **Radial Menu**.
   - Use menu shortcuts to open **Prompts**, **Favorites**, or create a **New** prompt.
   - The menu smart-adapts its layout based on where you drag it.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
