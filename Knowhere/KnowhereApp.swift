//
//  KnowhereApp.swift
//  Knowhere - AI Prompt Manager
//
//  A native macOS app to collect, organize, and quickly access AI prompts
//

import SwiftUI
import Carbon.HIToolbox
import Foundation

@main
struct KnowhereApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Use the SINGLETON PromptStore - all components share this ONE instance
    @ObservedObject private var promptStore = PromptStore.shared

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            ContentView()
                .environmentObject(promptStore)
                .frame(minWidth: 800, minHeight: 600)
                .onReceive(NotificationCenter.default.publisher(for: .showNewPromptSheet)) { _ in
                    showingNewPrompt = true
                }
                .onAppear {
                    // Share PromptStore reference with AppDelegate (for programmatic windows)
                    appDelegate.sharedPromptStore = promptStore
                    
                    // Capture openWindow action when window appears
                    appDelegate.openMainWindowAction = openMainWindow
                    
                    // Configure this window to NOT be released when closed
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first(where: { $0.contentView != nil && !($0.contentView is NSHostingView<EmptyView>) }) {
                            window.isReleasedWhenClosed = false
                            window.delegate = appDelegate
                            appDelegate.swiftUIMainWindow = window
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Prompt") {
                    showNewPromptSheet()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(promptStore)
        }
    }

    @State private var showingNewPrompt = false

    private func showNewPromptSheet() {
        // Post notification that ContentView listens to
        NotificationCenter.default.post(name: .showNewPromptSheet, object: nil)
    }

    @Environment(\.openWindow) private var openWindow

    private func openMainWindow() {
        NSLog("🟢 SwiftUI openMainWindow called - invoking openWindow(id: mainWindow)")
        openWindow(id: "mainWindow")
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var floatingPanel: FloatingPanelController?
    var floatingBubble: FloatingBubbleController?
    
    // Shared PromptStore from SwiftUI (passed via onAppear)
    var sharedPromptStore: PromptStore?
    
    // Fallback PromptStore only used if SwiftUI hasn't loaded yet
    private var fallbackPromptStore: PromptStore?
    
    // Reference to SwiftUI-created main window
    var swiftUIMainWindow: NSWindow?
    
    var eventMonitor: Any?
    var openMainWindowAction: (() -> Void)?
    var programmaticMainWindow: NSWindow?

    // Computed property to get the best available PromptStore
    var promptStore: PromptStore {
        if let shared = sharedPromptStore {
            return shared
        }
        if fallbackPromptStore == nil {
            fallbackPromptStore = PromptStore()
        }
        return fallbackPromptStore!
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up floating bubble (AssistiveTouch-like)
        // Note: FloatingBubbleController will use its own PromptStore initially
        // This is fine for display, but we should update it when shared store is available
        floatingBubble = FloatingBubbleController()
        floatingBubble?.show()

        // Set up floating panel (for ⌥ Space hotkey)
        floatingPanel = FloatingPanelController()

        // Register global hotkey (Option + Space)
        registerGlobalHotkey()

        // Make app appear in dock
        NSApp.setActivationPolicy(.regular)

        // Listen for open main window requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openMainWindow),
            name: .openMainWindow,
            object: nil
        )

        // Listen for settings requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsWindow),
            name: .openSettingsWindow,
            object: nil
        )

        // Listen for new prompt requests (ensure window is open first)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewPromptRequest),
            name: .newPrompt,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Allow the window to close, but hide it instead of releasing
        NSLog("🟡 windowShouldClose - hiding window instead of closing")
        sender.orderOut(nil)
        return false  // Prevent actual close, we just hid it
    }

    func registerGlobalHotkey() {
        // Using local monitor for now (works when app is active)
        // For true global hotkey, we'd need accessibility permissions
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Option + Space - toggle floating panel
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                self?.toggleFloatingPanel()
                return nil
            }
            // Option + B - toggle floating bubble
            if event.modifierFlags.contains(.option) && event.keyCode == 11 {
                self?.toggleFloatingBubble()
                return nil
            }
            return event
        }

        // Also add global monitor (requires accessibility permissions)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                self?.toggleFloatingPanel()
            }
            if event.modifierFlags.contains(.option) && event.keyCode == 11 {
                self?.toggleFloatingBubble()
            }
        }
    }

    @objc func toggleFloatingPanel() {
        floatingPanel?.toggle()
    }

    @objc func toggleFloatingBubble() {
        floatingBubble?.toggle()
    }

    @objc func openMainWindow() {
        NSLog("🔵 openMainWindow called")

        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.regular)

        // PRIORITY 1: Check if SwiftUI-created window exists and can be shown
        if let swiftUIWindow = swiftUIMainWindow {
            NSLog("🟢 Found SwiftUI main window reference - showing it")
            swiftUIWindow.setIsVisible(true)
            swiftUIWindow.makeKeyAndOrderFront(nil)
            swiftUIWindow.orderFrontRegardless()
            return
        }
        
        // PRIORITY 2: Check if programmatic window exists
        if let progWindow = programmaticMainWindow, progWindow.contentView != nil {
            NSLog("🟢 Found programmatic main window - showing it")
            progWindow.setIsVisible(true)
            progWindow.makeKeyAndOrderFront(nil)
            progWindow.orderFrontRegardless()
            return
        }

        // PRIORITY 3: Search for any hidden main window
        let candidateWindows = NSApp.windows.filter { window in
            // Exclude floating panels, settings, and system windows
            guard window.contentView != nil else { return false }
            guard !window.title.contains("Settings") else { return false }
            guard window.styleMask.contains(.titled) else { return false }
            guard window.level == .normal else { return false }
            return true
        }

        NSLog("🔵 Found \(candidateWindows.count) candidate window(s)")

        if let mainWindow = candidateWindows.first {
            NSLog("🟢 Showing existing candidate window")
            mainWindow.setIsVisible(true)
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
            
            // Store reference for future use
            swiftUIMainWindow = mainWindow
            mainWindow.isReleasedWhenClosed = false
            mainWindow.delegate = self
            return
        }

        // PRIORITY 4: No window exists - create one programmatically
        NSLog("🔴 No window exists - creating programmatic window")
        createProgrammaticMainWindow()
    }
    
    private func createProgrammaticMainWindow() {
        // Use shared PromptStore if available, otherwise use fallback
        let store = promptStore
        NSLog("🔵 Using PromptStore: \(sharedPromptStore != nil ? "shared" : "fallback")")

        // Create SwiftUI view with proper PromptStore
        let contentView = ContentView()
            .environmentObject(store)
            .frame(minWidth: 800, minHeight: 600)

        // Create hosting view (bridge SwiftUI to AppKit)
        let hostingView = NSHostingView(rootView: contentView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Knowhere"
        window.contentView = hostingView
        window.center()
        window.setFrameAutosaveName("mainWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self

        // Store reference
        programmaticMainWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSLog("🟢 Programmatic window created and shown")
    }

    @objc func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Try to find existing Settings window
        let settingsWindow = NSApp.windows.first(where: { $0.title.contains("Settings") })
        if let window = settingsWindow {
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        // Open Settings via app menu - Settings scene auto-adds itself to the Application menu
        if let appMenu = NSApp.mainMenu?.items.first {
            for menuItem in appMenu.submenu?.items ?? [] {
                if menuItem.title.contains("Settings") || menuItem.title.contains("Preferences") {
                    if let action = menuItem.action {
                        NSApp.sendAction(action, to: menuItem.target, from: menuItem)
                    }
                    return
                }
            }
        }

        // Fallback: try to trigger via responder chain
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    @objc func handleNewPromptRequest() {
        NSLog("🔵 handleNewPromptRequest called")
        
        // First ensure main window is open and visible
        openMainWindow()
        
        // Activate app to ensure it receives focus
        NSApp.activate(ignoringOtherApps: true)

        // Longer delay to ensure window is fully ready and view hierarchy is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSLog("🔵 Posting showNewPromptSheet notification")
            // Post the sheet notification after window is visible
            NotificationCenter.default.post(name: .showNewPromptSheet, object: nil)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newPrompt = Notification.Name("newPrompt")
    static let showNewPromptSheet = Notification.Name("showNewPromptSheet")
    static let toggleFloatingPanel = Notification.Name("toggleFloatingPanel")
    static let openMainWindow = Notification.Name("openMainWindow")
    static let openSettingsWindow = Notification.Name("openSettingsWindow")
}
