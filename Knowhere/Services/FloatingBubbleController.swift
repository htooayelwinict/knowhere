//
//  FloatingBubbleController.swift
//  Knowhere
//
//  Creates an iPhone AssistiveTouch-like floating bubble
//  with radial flare menu animation
//

import SwiftUI
import AppKit

class FloatingBubbleController: NSObject {
    private var bubbleWindow: NSWindow?
    private var radialMenuWindow: NSWindow?
    private var submenuWindow: NSWindow?
    private var promptStore: PromptStore
    private var isExpanded = false
    private var bubblePosition: NSPoint = .zero
    
    // Determine menu HORIZONTAL direction based on bubble position
    private var currentHorizontalDirection: MenuHorizontalDirection {
        guard let screen = NSScreen.main else { return .left }
        let screenMidX = screen.visibleFrame.midX
        // If bubble is on right half of screen, show menu to the left
        return bubblePosition.x > screenMidX ? .left : .right
    }
    
    // Determine menu VERTICAL direction based on bubble position
    private var currentVerticalDirection: MenuVerticalDirection {
        guard let screen = NSScreen.main else { return .up }
        let screenMidY = screen.visibleFrame.midY
        // If bubble is in top half of screen, spread items downward
        return bubblePosition.y > screenMidY ? .down : .up
    }
    
    static let bubbleSize: CGFloat = 56
    static let menuWidth: CGFloat = 200
    static let menuHeight: CGFloat = 420
    static let submenuWidth: CGFloat = 300
    static let submenuHeight: CGFloat = 340
    
    override init() {
        self.promptStore = PromptStore()
        super.init()
        setupBubble()
        setupRadialMenu()
    }
    
    // MARK: - Setup
    
    private func setupBubble() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - Self.bubbleSize - 20
        let y = screenFrame.minY + 100
        bubblePosition = NSPoint(x: x, y: y)
        
        let bubbleWindow = NSWindow(
            contentRect: NSRect(x: x, y: y, width: Self.bubbleSize, height: Self.bubbleSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        bubbleWindow.level = .floating
        bubbleWindow.backgroundColor = .clear
        bubbleWindow.isOpaque = false
        bubbleWindow.hasShadow = true
        bubbleWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        bubbleWindow.isMovableByWindowBackground = false
        bubbleWindow.ignoresMouseEvents = false
        
        let bubbleView = AssistiveTouchBubbleView(
            onTap: { [weak self] in self?.toggleMenu() },
            onDragStart: { [weak self] in self?.startDrag() },
            onDrag: { [weak self] translation in self?.moveBubble(by: translation) },
            onDragEnd: { [weak self] in self?.endDrag() }
        )
        
        let hostingView = NSHostingView(rootView: bubbleView)
        bubbleWindow.contentView = hostingView
        
        self.bubbleWindow = bubbleWindow
    }
    
    private func setupRadialMenu() {
        let radialMenuWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.menuWidth, height: Self.menuHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        radialMenuWindow.level = .floating
        radialMenuWindow.backgroundColor = .clear
        radialMenuWindow.isOpaque = false
        radialMenuWindow.hasShadow = false
        radialMenuWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        radialMenuWindow.ignoresMouseEvents = false
        
        self.radialMenuWindow = radialMenuWindow
    }
    
    // MARK: - Show/Hide
    
    func show() {
        bubbleWindow?.orderFront(nil)
    }
    
    func hide() {
        bubbleWindow?.orderOut(nil)
        collapse()
    }
    
    func toggle() {
        if bubbleWindow?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
    
    // MARK: - Bubble Movement
    
    private var dragStartWindowPosition: NSPoint?
    private var dragStartMousePosition: NSPoint?
    
    func startDrag() {
        // Capture BOTH window position AND mouse screen position at drag start
        dragStartWindowPosition = bubblePosition
        dragStartMousePosition = NSEvent.mouseLocation
    }
    
    func moveBubble(by translation: CGSize) {
        guard let window = bubbleWindow,
              let startWindowPos = dragStartWindowPosition,
              let startMousePos = dragStartMousePosition else { return }
        
        // Get current mouse position in screen coordinates
        let currentMousePos = NSEvent.mouseLocation
        
        // Calculate actual screen delta from mouse movement
        let deltaX = currentMousePos.x - startMousePos.x
        let deltaY = currentMousePos.y - startMousePos.y
        
        // Apply delta to original window position
        var newOrigin = NSPoint(
            x: startWindowPos.x + deltaX,
            y: startWindowPos.y + deltaY
        )
        
        // Clamp to screen bounds
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            newOrigin.x = max(screenFrame.minX, min(newOrigin.x, screenFrame.maxX - Self.bubbleSize))
            newOrigin.y = max(screenFrame.minY, min(newOrigin.y, screenFrame.maxY - Self.bubbleSize))
        }
        
        // Direct window update - no animation for responsiveness
        window.setFrameOrigin(newOrigin)
        bubblePosition = newOrigin
        
        if isExpanded {
            updateRadialMenuPosition()
        }
    }
    
    func endDrag() {
        dragStartWindowPosition = nil
        dragStartMousePosition = nil
    }
    
    // MARK: - Radial Menu
    
    private func toggleMenu() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    private func expand() {
        guard !isExpanded, let radialMenuWindow = radialMenuWindow else { return }
        isExpanded = true
        
        let hDir = currentHorizontalDirection
        let vDir = currentVerticalDirection
        
        // Create radial menu view with binding to expanded state
        let radialView = RadialMenuHostView(
            isExpanded: true,
            horizontalDirection: hDir,
            verticalDirection: vDir,
            onAction: { [weak self] action in
                self?.handleAction(action)
            },
            onClose: { [weak self] in
                self?.collapse()
            }
        )
        
        let hostingView = NSHostingView(rootView: radialView)
        radialMenuWindow.contentView = hostingView
        
        updateRadialMenuPosition()
        radialMenuWindow.alphaValue = 1
        radialMenuWindow.orderFront(nil)
        
        // Animate expansion after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard let self = self else { return }
            if let hostingView = radialMenuWindow.contentView as? NSHostingView<RadialMenuHostView> {
                hostingView.rootView = RadialMenuHostView(
                    isExpanded: true,
                    horizontalDirection: hDir,
                    verticalDirection: vDir,
                    onAction: { [weak self] action in
                        self?.handleAction(action)
                    },
                    onClose: { [weak self] in
                        self?.collapse()
                    }
                )
            }
        }
    }
    
    private func updateRadialMenuPosition() {
        guard let radialMenuWindow = radialMenuWindow else { return }
        
        let hDir = currentHorizontalDirection
        let vDir = currentVerticalDirection
        
        // The bubble's center point
        let bubbleCenterX = bubblePosition.x + Self.bubbleSize / 2
        let bubbleCenterY = bubblePosition.y + Self.bubbleSize / 2
        
        var x: CGFloat
        var y: CGFloat
        
        // Calculate menu position so it appears DIRECTLY ADJACENT to the bubble
        // The menu window needs to be positioned so the menu items "grow out" from the bubble
        
        // Horizontal: menu window edge should touch the bubble
        if hDir == .left {
            // Menu window's RIGHT edge should be near the bubble's LEFT edge
            x = bubblePosition.x - Self.menuWidth + 20  // Small overlap for visual connection
        } else {
            // Menu window's LEFT edge should be near the bubble's RIGHT edge
            x = bubblePosition.x + Self.bubbleSize - 20  // Small overlap for visual connection
        }
        
        // Vertical: position depends on spread direction
        // Menu items are aligned within the window based on direction
        if vDir == .up {
            // Items spread upward FROM the bubble
            // Menu window's BOTTOM edge should align with bubble's vertical center
            y = bubbleCenterY - 50  // Offset so first item appears at bubble level
        } else {
            // Items spread downward FROM the bubble
            // Menu window's TOP edge should align with bubble's vertical center
            y = bubbleCenterY - Self.menuHeight + 50  // Position window so items grow down
        }
        
        radialMenuWindow.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        
        let hDir = currentHorizontalDirection
        let vDir = currentVerticalDirection
        
        // update view state to trigger reverse animation
        if let radialMenuWindow = radialMenuWindow,
           let hostingView = radialMenuWindow.contentView as? NSHostingView<RadialMenuHostView> {
            hostingView.rootView = RadialMenuHostView(
                isExpanded: false,
                horizontalDirection: hDir,
                verticalDirection: vDir,
                onAction: { _ in }
            )
            
            // Fade out window alongside view animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                radialMenuWindow.animator().alphaValue = 0
            }
        }
        
        // Hide after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.radialMenuWindow?.orderOut(nil)
            self?.submenuWindow?.orderOut(nil)
            self?.submenuWindow = nil
        }
    }
    
    // MARK: - Actions
    
    private func handleAction(_ action: RadialAction) {
        switch action {
        case .prompts:
            showSubmenu(with: promptStore.prompts, title: "All Prompts")
        case .favorites:
            showSubmenu(with: promptStore.prompts.filter { $0.isFavorite }, title: "Favorites")
        case .recent:
            showSubmenu(with: promptStore.recentPrompts, title: "Recent")
        case .newPrompt:
            // Post notification to AppDelegate to handle (opens window + shows sheet)
            NotificationCenter.default.post(name: .newPrompt, object: nil)
            collapse()
        case .settings:
            // Post notification to AppDelegate to open Settings
            NotificationCenter.default.post(name: .openSettingsWindow, object: nil)
            collapse()
        case .openApp:
            openMainApp()
            collapse()
        }
    }
    
    private func showSubmenu(with prompts: [Prompt], title: String) {
        let submenuView = RadialSubmenuView(
            prompts: prompts,
            title: title,
            onCopy: { [weak self] prompt in
                self?.promptStore.copyPrompt(prompt)
                self?.collapse()
            },
            onClose: { [weak self] in
                self?.hideSubmenu()
            }
        )
        
        let submenuWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.submenuWidth, height: Self.submenuHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        submenuWindow.level = .floating
        submenuWindow.backgroundColor = .clear
        submenuWindow.isOpaque = false
        submenuWindow.hasShadow = true
        submenuWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: submenuView)
        submenuWindow.contentView = hostingView
        
        // Position submenu to left of bubble
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        var x = bubblePosition.x - Self.submenuWidth - 20
        if x < screenFrame.minX {
            x = bubblePosition.x + Self.bubbleSize + 20
        }
        let y = bubblePosition.y + Self.bubbleSize / 2 - Self.submenuHeight / 2
        
        submenuWindow.setFrameOrigin(NSPoint(x: x, y: max(screenFrame.minY + 10, y)))
        
        submenuWindow.alphaValue = 0
        submenuWindow.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            submenuWindow.animator().alphaValue = 1
        }
        
        self.submenuWindow = submenuWindow
    }
    
    private func hideSubmenu() {
        guard let submenuWindow = submenuWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            submenuWindow.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.submenuWindow?.orderOut(nil)
            self?.submenuWindow = nil
        })
    }
    
    private func openMainApp() {
        // Post notification to AppDelegate to properly restore main window
        NSLog("📣 Posting .openMainWindow notification")
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
    }
}

// MARK: - RadialMenuHostView (Wrapper for tree menu)
struct RadialMenuHostView: View {
    let isExpanded: Bool
    let horizontalDirection: MenuHorizontalDirection
    let verticalDirection: MenuVerticalDirection
    let onAction: (RadialAction) -> Void
    var onClose: (() -> Void)? = nil
    
    // Compute alignment based on both directions
    private var alignment: Alignment {
        switch (horizontalDirection, verticalDirection) {
        case (.left, .up): return .bottomTrailing
        case (.left, .down): return .topTrailing
        case (.right, .up): return .bottomLeading
        case (.right, .down): return .topLeading
        }
    }
    
    var body: some View {
        ZStack(alignment: alignment) {
            // Tap-to-close background
            if isExpanded {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose?()
                    }
            }
            
            RadialMenuView(
                isExpanded: isExpanded,
                horizontalDirection: horizontalDirection,
                verticalDirection: verticalDirection,
                onAction: onAction
            )
        }
        .frame(width: 200, height: 420)
    }
}

// MARK: - Radial Submenu View (for prompts list)
struct RadialSubmenuView: View {
    let prompts: [Prompt]
    let title: String
    let onCopy: (Prompt) -> Void
    let onClose: () -> Void
    
    @State private var searchText = ""
    
    var filteredPrompts: [Prompt] {
        if searchText.isEmpty {
            return prompts
        }
        return prompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Prompts list
            if filteredPrompts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("No prompts")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredPrompts) { prompt in
                            SubmenuPromptRow(prompt: prompt) {
                                onCopy(prompt)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                }
            }
        }
        .frame(width: 300, height: 340)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Submenu Prompt Row
struct SubmenuPromptRow: View {
    let prompt: Prompt
    let onCopy: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(prompt.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if prompt.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(prompt.content)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isHovering {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.white.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - AssistiveTouch Bubble View
struct AssistiveTouchBubbleView: View {
    var onTap: () -> Void
    var onDragStart: () -> Void
    var onDrag: (CGSize) -> Void
    var onDragEnd: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#10a37f")?.opacity(0.7) ?? Color.green.opacity(0.7),
                            Color(hex: "#10a37f")?.opacity(0.2) ?? Color.green.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 18,
                        endRadius: 35
                    )
                )
                .frame(width: 56, height: 56)
                .blur(radius: isDragging ? 15 : (isHovering ? 12 : 8))
            
            // Glass background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: isPressed ? 46 : (isDragging ? 54 : (isHovering ? 52 : 48)), 
                       height: isPressed ? 46 : (isDragging ? 54 : (isHovering ? 52 : 48)))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(isDragging ? 0.5 : 0.35), radius: isDragging ? 16 : 12, x: 0, y: isDragging ? 8 : 5)
            
            // Inner icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#10a37f") ?? .green,
                                Color(hex: "#0d8c6d") ?? .green
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: Color(hex: "#10a37f")?.opacity(0.5) ?? .green.opacity(0.5), radius: 8, x: 0, y: 2)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.85 : (isDragging ? 1.15 : (isHovering ? 1.08 : 1.0)))
        }
        .frame(width: 56, height: 56)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    // On first drag movement, notify start
                    if !isDragging {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isDragging = true
                        }
                        onDragStart()
                    }
                    
                    // Pass absolute translation (not delta) - controller handles position
                    onDrag(value.translation)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isDragging = false
                    }
                    onDragEnd()
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                        onTap()
                    }
                }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

#Preview("Bubble") {
    AssistiveTouchBubbleView(onTap: {}, onDragStart: {}, onDrag: { _ in }, onDragEnd: {})
        .frame(width: 80, height: 80)
        .background(Color.gray.opacity(0.3))
}
