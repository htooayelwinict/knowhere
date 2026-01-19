# Bug Fixes & Issues Resolved

## January 20, 2026

### Issue: Recent Submenu Hanging & Unable to Close

**Severity:** High
**Status:** ✅ Fixed

#### Problem
The Recent submenu (and other submenus accessed from the radial menu) would hang and become impossible to close after opening multiple windows together. The UI would become unresponsive and orphaned submenu windows would accumulate.

#### Root Causes Identified

1. **Orphaned Submenu Windows**
   - Each time a submenu action was triggered (Recent, Favorites, Prompts), a NEW `NSWindow` was created
   - Previous submenu windows were NEVER closed before creating new ones
   - Orphaned windows would stack invisibly, causing the app to hang and consume resources
   - *Location:* `FloatingBubbleController.showSubmenu()`

2. **Race Condition in Window Reference Management**
   - The `hideSubmenu()` completion handler used `self?.submenuWindow` which could reference a different window than the one being animated
   - Multiple animations could collide, causing unpredictable behavior
   - *Location:* `FloatingBubbleController.hideSubmenu()`

3. **Delayed Cleanup in collapse()**
   - `collapse()` used `DispatchQueue.main.asyncAfter` with a 0.35s delay to nil out the submenu reference
   - If user quickly re-opened the menu, the old timer would nil out the NEW submenu window
   - This caused reference loss and window orphaning
   - *Location:* `FloatingBubbleController.collapse()`

4. **Redundant Window Management**
   - Both `collapse()` and the hover timer were calling `hideSubmenu()`, creating conflicting cleanup logic
   - This made the control flow unpredictable

#### Solutions Implemented

**1. Synchronized Submenu Cleanup**
```swift
private func showSubmenu(with prompts: [Prompt], title: String) {
    // CRITICAL: Close any existing submenu first
    hideSubmenuImmediately()  // ← NEW: Cleanup before creating new window
    
    let submenuWindow = NSWindow(...)
    // ... rest of setup
}

// NEW: Immediate cleanup without animation
private func hideSubmenuImmediately() {
    submenuWindow?.orderOut(nil)
    submenuWindow = nil
}
```

**2. Fixed Race Condition in hideSubmenu()**
```swift
private func hideSubmenu() {
    guard let windowToHide = submenuWindow else { return }
    
    // Clear reference IMMEDIATELY to prevent race conditions
    self.submenuWindow = nil
    
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.2
        context.timingFunction = CAMediaTimingFunction(name: .easeIn)
        windowToHide.animator().alphaValue = 0  // ← Animate SPECIFIC window
    }, completionHandler: {
        windowToHide.orderOut(nil)  // ← Hide SPECIFIC window
    })
}
```

**3. Synchronous Cleanup in collapse()**
```swift
private func collapse() {
    guard isExpanded else { return }
    isExpanded = false
    
    // CRITICAL: Immediately hide and release submenu
    hideSubmenuImmediately()  // ← NEW: Synchronous cleanup
    
    // Animate radial menu fade-out
    // ... animation code ...
    
    // Hide menu window after animation (only radial menu now)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
        self?.radialMenuWindow?.orderOut(nil)
    }
}
```

**4. Simplified Hover Logic**
```swift
// Removed redundant hideSubmenu() call since collapse() now handles it
hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
    guard let self = self, self.dragStartWindowPosition == nil else { return }
    self.collapse()  // ← This now handles submenu cleanup
}
```

#### Technical Details

**Window Management Flow (After Fix)**
```
User clicks "Recent" on radial menu
    ↓
handleAction(.recent) is called
    ↓
showSubmenu() is called
    ↓
hideSubmenuImmediately() closes ANY existing submenu
    ↓
Create NEW submenu window
    ↓
Store reference: self.submenuWindow = newWindow
    ↓
Animate window in
```

**Collapse Flow (After Fix)**
```
Menu should close (from hover timeout or action)
    ↓
collapse() is called
    ↓
hideSubmenuImmediately() closes submenu synchronously
    ↓
Animate radial menu fade-out
    ↓
After 0.35s, hide radial menu window
    ↓
All windows properly released
```

#### Files Modified
- `Knowhere/Services/FloatingBubbleController.swift`
  - Lines 305-337: Updated `collapse()` method
  - Lines 366-448: Updated `showSubmenu()` method
  - Lines 450-460: Added `hideSubmenuImmediately()` method
  - Lines 462-473: Refactored `hideSubmenu()` method
  - Lines 141-154: Simplified hover timer logic

#### Testing Recommendations

1. **Basic Submenu Navigation**
   - Open bubble menu
   - Click "Recent" → Should display recent prompts
   - Click "Favorites" → Should close Recent submenu and show Favorites
   - Click "Prompts" → Should close Favorites submenu and show all prompts

2. **Stress Test (Multiple Quick Clicks)**
   - Rapidly click different submenu items
   - Menu should remain responsive
   - No orphaned windows
   - No memory leaks

3. **Window Closing**
   - Open submenu
   - Click X button on submenu header
   - Window should close immediately without hanging
   - Hover away from menu → Should auto-collapse after 0.8s

4. **Combined Window Scenarios**
   - Open main window (Cmd+Space or from menu)
   - Open bubble menu and recent submenu
   - Switch between windows
   - All windows should remain responsive
   - Closing any window should not affect others

#### Performance Impact
- **Positive:** Eliminated window orphaning, reduced memory leaks
- **No negative impact:** Cleanup is synchronous and fast (submenu is hidden before new one creates)

#### Related Issues
- None currently known

---

## Notes for Future Development

The window management pattern used here should be applied to other floating windows in the app:
- Floating panel windows
- Settings windows
- Any other temporary UI overlays

Consider implementing a `WindowManager` singleton to centralize window lifecycle management and prevent similar issues in the future.
