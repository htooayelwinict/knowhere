//
//  FloatingPanelController.swift
//  Knowhere
//
//  Manages the floating panel window that stays on top of other apps
//

import SwiftUI
import AppKit

class FloatingPanelController: NSObject {
    private var panel: NSPanel?
    private var promptStore: PromptStore
    
    var isVisible: Bool {
        panel?.isVisible ?? false
    }
    
    override init() {
        self.promptStore = PromptStore()
        super.init()
        setupPanel()
    }
    
    private func setupPanel() {
        // Create the panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties
        panel.title = "Knowhere"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        // Keep on top of other windows
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set up the SwiftUI content
        let contentView = FloatingPanelView(promptStore: promptStore) { [weak self] in
            self?.hide()
        }
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Position in top-right corner of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.maxX - panelFrame.width - 20
            let y = screenFrame.maxY - panelFrame.height - 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.panel = panel
    }
    
    func show() {
        panel?.makeKeyAndOrderFront(nil)
        panel?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
}
