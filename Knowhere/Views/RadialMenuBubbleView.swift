//
//  RadialMenuBubbleView.swift
//  Knowhere
//
//  Tree branch menu with clean vertical layout - fully location-aware
//

import SwiftUI
import AppKit

// MARK: - Menu Direction (based on bubble position)
enum MenuHorizontalDirection {
    case left   // Menu opens to the left of bubble
    case right  // Menu opens to the right of bubble
}

enum MenuVerticalDirection {
    case up     // Menu items spread upward (when bubble is at bottom)
    case down   // Menu items spread downward (when bubble is at top)
}

// MARK: - Menu Action
enum RadialAction: String, CaseIterable, Identifiable {
    case prompts = "Prompts"
    case favorites = "Favorites"
    case recent = "Recent"
    case newPrompt = "New"
    case settings = "Settings"
    case openApp = "Open"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .prompts: return "text.bubble.fill"
        case .favorites: return "star.fill"
        case .recent: return "clock.fill"
        case .newPrompt: return "plus"
        case .settings: return "gearshape.fill"
        case .openApp: return "arrow.up.forward.app.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .prompts: return Color(hex: "#3B82F6") ?? .blue
        case .favorites: return Color(hex: "#F59E0B") ?? .orange
        case .recent: return Color(hex: "#06B6D4") ?? .cyan
        case .newPrompt: return Color(hex: "#10B981") ?? .green
        case .settings: return Color(hex: "#8B5CF6") ?? .purple
        case .openApp: return Color(hex: "#EC4899") ?? .pink
        }
    }
}

// MARK: - Single Menu Item Button
struct TreeMenuButton: View {
    let action: RadialAction
    let index: Int
    let isExpanded: Bool
    let horizontalDirection: MenuHorizontalDirection
    let verticalDirection: MenuVerticalDirection
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    private let buttonHeight: CGFloat = 42
    private let buttonWidth: CGFloat = 150
    private let itemSpacing: CGFloat = 50
    
    // Offset based on vertical direction
    var offsetY: CGFloat {
        guard isExpanded else { return 0 }
        let baseOffset = CGFloat(index + 1) * itemSpacing
        return verticalDirection == .up ? -baseOffset : baseOffset
    }
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 10) {
                if horizontalDirection == .right {
                    Spacer()
                    
                    // Label first for right direction
                    Text(action.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    // Icon circle
                    iconCircle
                } else {
                    // Icon circle first for left direction
                    iconCircle
                    
                    // Label
                    Text(action.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .frame(width: buttonWidth, height: buttonHeight)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [action.color.opacity(0.5), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .offset(y: offsetY)
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.5)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75).delay(isExpanded ? Double(index) * 0.04 : 0),
            value: isExpanded
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }
    
    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(action.color)
                .frame(width: 32, height: 32)
                .shadow(color: action.color.opacity(0.6), radius: isHovering ? 10 : 5, x: 0, y: 2)
            
            Image(systemName: action.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Tree Menu Container
struct RadialMenuView: View {
    let isExpanded: Bool
    let horizontalDirection: MenuHorizontalDirection
    let verticalDirection: MenuVerticalDirection
    let onAction: (RadialAction) -> Void
    
    private let buttonCount = RadialAction.allCases.count
    private let itemSpacing: CGFloat = 50
    
    // Line X position based on direction
    var lineX: CGFloat {
        horizontalDirection == .left ? 30 : 150
    }
    
    var body: some View {
        ZStack(alignment: alignment) {
            // Connection line
            if isExpanded {
                connectionLine
            }
            
            // Menu buttons
            ForEach(Array(RadialAction.allCases.enumerated()), id: \.element.id) { index, action in
                TreeMenuButton(
                    action: action,
                    index: index,
                    isExpanded: isExpanded,
                    horizontalDirection: horizontalDirection,
                    verticalDirection: verticalDirection,
                    onTap: { onAction(action) }
                )
            }
        }
        .frame(width: 180, height: 400)
    }
    
    private var alignment: Alignment {
        switch (horizontalDirection, verticalDirection) {
        case (.left, .up): return .bottomTrailing
        case (.left, .down): return .topTrailing
        case (.right, .up): return .bottomLeading
        case (.right, .down): return .topLeading
        }
    }
    
    private var connectionLine: some View {
        Path { path in
            path.move(to: CGPoint(x: lineX, y: 0))
            for i in 0..<buttonCount {
                let offset = CGFloat(i + 1) * itemSpacing
                let y = verticalDirection == .up ? -offset : offset
                path.addLine(to: CGPoint(x: lineX, y: y))
            }
        }
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.25), .white.opacity(0.08)],
                startPoint: verticalDirection == .up ? .bottom : .top,
                endPoint: verticalDirection == .up ? .top : .bottom
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .animation(.easeOut(duration: 0.25), value: isExpanded)
    }
}

// MARK: - Preview
#Preview("Menu - Bottom Right (up/left)") {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                RadialMenuView(isExpanded: true, horizontalDirection: .left, verticalDirection: .up) { _ in }
            }
        }
    }
    .frame(width: 300, height: 500)
}

#Preview("Menu - Top Left (down/right)") {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        VStack {
            HStack {
                RadialMenuView(isExpanded: true, horizontalDirection: .right, verticalDirection: .down) { _ in }
                Spacer()
            }
            Spacer()
        }
    }
    .frame(width: 300, height: 500)
}
