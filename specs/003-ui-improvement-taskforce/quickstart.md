# Quickstart: UI Improvement Taskforce Manual Validation

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Version**: 1.0.0

## Purpose

Manual UI validation workflow for QA and developers to verify UI improvements are working correctly across platforms. This quickstart covers widget functionality, canvas rendering, error handling, responsive layouts, and accessibility.

## Prerequisites

### Required Devices/Platforms
- **Physical Device (iOS or Android)**: For touch gesture testing
- **Simulator/Emulator**: For quick iterations
- **Desktop Browser** (optional): For web testing

### Required Files
- Example automata from `jflutter_js/examples/`:
  - `afd_ends_with_a.json`
  - `afn_lambda_a_or_ab.json`
  - `apda_palindrome.json`
  - `tm_binary_to_unary.json`
- Invalid test file (create manually): `invalid_automaton.jff` with malformed XML

### Build and Run
```bash
cd <jflutter-repo-root>

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run on macOS desktop
flutter run -d macos

# Run on web
flutter run -d chrome
```

## Validation Checklist

### ✅ Section 1: FSA Canvas Validation (Priority 1)

#### 1.1 Empty Canvas State
- [ ] Launch app and navigate to FSA editor
- [ ] Verify empty canvas shows:
  - Gray background with border
  - "Empty Canvas" message with icon (centered)
  - "Add state" action visible in the toolbar (desktop) or mobile control tray (bottom)
- [ ] Canvas controls not blocked by layout

#### 1.2 State Creation
- [ ] Tap "Add state" action
- [ ] Tap on canvas at position (200, 150)
- [ ] Verify state appears:
  - Circle (30px radius)
  - Label "q0" centered
  - Blue border (initial state arrow from left)
- [ ] Add 5 more states at different positions
- [ ] Verify all states render without overlap
- [ ] Performance: Canvas remains smooth (60fps)

#### 1.3 Transition Creation
- [ ] Tap "Add Transition" button
- [ ] Tap state q0, then tap state q1
- [ ] Enter symbol "1" in dialog
- [ ] Verify transition renders:
  - Arrow from q0 to q1
  - Label "1" at midpoint
  - Arrow head pointing to q1
- [ ] Create multiple transitions between same states
- [ ] Verify curved arrows for multiple transitions

#### 1.4 State Selection and Editing
- [ ] Tap on state q0
- [ ] Verify state highlighted (blue border, 3px width)
- [ ] Long-press on state q0
- [ ] Verify edit dialog appears:
  - Label field
  - "Initial" checkbox
  - "Accepting" checkbox
- [ ] Check "Accepting"
- [ ] Save changes
- [ ] Verify double circle for accepting state

#### 1.5 Trace Visualization
- [ ] Create simple DFA: q0 --1--> q1 (q1 accepting)
- [ ] Enter input string "1" in simulation panel
- [ ] Tap "Simulate"
- [ ] Verify trace visualization:
  - q0 highlighted green (visited)
  - q1 highlighted blue (current/final)
  - Transition q0→q1 highlighted green (used)
  - Trace path drawn (blue dotted line)
- [ ] Step through simulation (if step controls available)
- [ ] Verify immutable trace (previous steps unchanged)

#### 1.6 Touch Gestures
- [ ] **Pan**: Drag state q0 to new position
  - Verify state moves smoothly
  - Transitions update endpoints
- [ ] **Pinch**: Pinch to zoom on canvas
  - Verify zoom level changes (0.5x - 2.0x range)
  - States/transitions scale appropriately
- [ ] **Viewport Pan**: Drag empty canvas area
  - Verify canvas pans (all states move together)
- [ ] Verify no gesture conflicts (state move vs. canvas pan)

### ✅ Section 2: PDA Canvas Validation (Priority 2)

#### 2.1 Stack Visualization
- [ ] Navigate to PDA editor
- [ ] Import `apda_palindrome.json`
- [ ] Verify stack panel visible (right side, 300px width)
- [ ] Stack initially shows bottom marker (Z)

#### 2.2 Push/Pop Operations
- [ ] Simulate input "aba" on palindrome PDA
- [ ] Step through simulation
- [ ] Verify stack grows upward:
  - Symbols appear from bottom to top
  - Top symbol highlighted (light blue)
  - Push animation smooth (200ms slide-in)
- [ ] Continue simulation to pop phase
- [ ] Verify pop animation (200ms slide-out)

#### 2.3 Transition Labels
- [ ] Verify PDA transition labels format:
  - Example: `a / Z → AZ`
  - Three parts separated by " / " and " → "
- [ ] Labels readable (11px font, white background)

### ✅ Section 3: TM Canvas Validation (Priority 3)

#### 3.1 Tape Rendering
- [ ] Navigate to TM editor
- [ ] Import `tm_binary_to_unary.json`
- [ ] Verify tape panel (top of canvas, full width, 80px height)
- [ ] Tape shows:
  - 11 visible cells (5 left, current, 5 right)
  - Current cell highlighted yellow (#FFF9C4)
  - Cells: 60x60px squares
  - Symbols centered (16px font)

#### 3.2 Head Position
- [ ] Verify head indicator:
  - Red triangle pointing down at current cell
  - Size: 12px base, 15px height
- [ ] Step through simulation
- [ ] Verify head moves left/right correctly

#### 3.3 Halt States
- [ ] Run simulation to completion
- [ ] Verify halt state indication:
  - Accept: Green double circle
  - Reject (if any): Red double circle
- [ ] TM stops at halt state

### ✅ Section 4: Error Handling Widgets

#### 4.1 File Operations Panel - Recoverable Failure
- [ ] Trigger a recoverable error (ex.: export automaton to read-only path)
- [ ] Verify inline ErrorBanner appears inside the panel:
  - Red background (#FFEBEE)
  - Error icon (left)
  - Message explaining the failure (no modal shown)
  - Retry button (uses global RetryButton styling)
  - Dismiss button (X icon)
- [ ] Tap "Retry" and confirm the operation is attempted again
- [ ] After success, verify the banner flips to informational blue with the success copy

#### 4.2 ImportErrorDialog - Critical Failure
- [ ] Attempt to import malformed file: `invalid_automaton.jff`
- [ ] Verify ImportErrorDialog opens immediately (no inline banner):
  - Modal (blocks background)
  - Title contextualised to the failure type
  - Filename shown in chip
  - Detailed recovery guidance + technical details toggle
  - Cancel and Retry buttons wired to RetryButton styling
- [ ] Tap outside dialog (verify not dismissible)
- [ ] Tap Cancel → dialog closes and panel clears retry state
- [ ] Re-open and tap Retry → dialog closes, picker reopens, and success banner is rendered after a valid file

#### 4.3 RetryButton States
- [ ] Find standalone RetryButton (if any, or use in banner)
- [ ] **Normal State**:
  - Refresh icon + "Retry" text
  - Primary color (blue)
  - Pressable
- [ ] Tap retry (if triggers loading):
  - **Loading State**:
  - Rotating refresh icon
  - Text: "Retrying..."
  - Disabled (no interaction)
- [ ] After completion:
  - **Normal State** restored OR
  - **Disabled State** (grayed out)

### ✅ Section 5: Responsive Layouts

#### 5.1 Mobile Layout (375px width)
- [ ] Resize window or use mobile device
- [ ] Verify:
  - Canvas controls accessible (not blocked)
  - Panels collapse/stack vertically
  - Buttons minimum 44x44px touch targets
  - No horizontal overflow
- [ ] Test on smallest screen (320px width)
- [ ] Verify minimum usability maintained

#### 5.2 Tablet Layout (768px width)
- [ ] Resize to tablet width
- [ ] Verify:
  - Side-by-side panels (canvas + simulation)
  - Panels collapsible
  - Canvas controls in top-right panel (compact)
  - All features accessible

#### 5.3 Desktop Layout (1280px width)
- [ ] Resize to desktop width
- [ ] Verify:
  - Multi-panel layout (canvas, simulation, algorithms)
  - All panels visible
  - Canvas controls expanded
  - Keyboard shortcuts work (if implemented)

#### 5.4 Blocked Buttons Check
- [ ] For each layout (mobile, tablet, desktop):
  - [ ] Add state action visible and tappable (toolbar or mobile tray)
  - [ ] Add transition workflow reachable (context menu or toolbar)
  - [ ] Simulate action visible and tappable
  - [ ] Save button visible and tappable
  - [ ] No buttons hidden behind panels or overlays

### ✅ Section 6: Accessibility Validation

#### 6.1 Screen Reader (iOS VoiceOver)
- [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
- [ ] Navigate to FSA canvas
- [ ] Swipe through elements
- [ ] Verify announcements:
  - "Automaton canvas, double tap state to edit, drag to move, pinch to zoom"
  - For state: "State q0, initial"
  - For transition: "Transition from q0 to q1, symbol: 1"
  - For controls: "Add state, button", "Simulate, button"

#### 6.2 Screen Reader (Android TalkBack)
- [ ] Enable TalkBack (Settings → Accessibility → TalkBack)
- [ ] Similar verification as iOS
- [ ] Verify all interactive elements have labels

#### 6.3 Touch Targets
- [ ] Measure button sizes (use Flutter DevTools)
- [ ] Verify all controls ≥44x44 logical pixels:
  - Add state action
  - Add transition affordance
  - Simulate action
  - Retry button
  - State/transition tap targets

#### 6.4 Contrast (Visual Check)
- [ ] Verify readable text contrast:
  - State labels: Black on white (high contrast)
  - Button text: White on blue (sufficient contrast)
  - Error text: Dark red on light red background (readable)
- [ ] No formal WCAG compliance required (best-effort)

#### 6.5 Keyboard Navigation (Desktop)
- [ ] Tab through interactive elements
- [ ] Verify focus indicators visible
- [ ] Enter key activates buttons
- [ ] Escape key closes dialogs

### ✅ Section 7: Performance Validation

#### 7.1 60fps Canvas Rendering
- [ ] Enable performance overlay: `flutter run --profile`
- [ ] Create automaton with 20 states, 50 transitions (max test complexity)
- [ ] Pan canvas
- [ ] Zoom canvas
- [ ] Verify: FPS counter stays ≥60fps (green bar)
- [ ] No dropped frames (red spikes)

#### 7.2 Large Automaton (Production Scale)
- [ ] Create/import automaton with 100+ states
- [ ] Verify viewport culling works:
  - Only visible states/transitions render
  - Performance remains smooth
- [ ] Zoom out
- [ ] Verify LOD (Level of Detail):
  - Labels disappear at low zoom
  - Circles remain visible

#### 7.3 Simulation Performance
- [ ] Run simulation with >1000 steps
- [ ] Verify:
  - Trace visualization smooth
  - Step navigation responsive
  - Memory usage <400MB (check DevTools)

### ✅ Section 8: Manual Save Workflow

#### 8.1 Unsaved Work Indicator
- [ ] Create new automaton (add states/transitions)
- [ ] Verify unsaved work indicator visible:
  - Dot or asterisk in app bar/title
  - "Unsaved changes" text
  - Visual cue (color change, icon)

#### 8.2 Manual Save
- [ ] Tap Save button (or menu → Save)
- [ ] Enter filename
- [ ] Save to device storage
- [ ] Verify unsaved indicator clears

#### 8.3 Catastrophic Failure Recovery
- [ ] Create complex automaton (10+ states)
- [ ] Save manually
- [ ] Force crash (if possible, or simulate memory error)
- [ ] Verify error dialog appears:
  - "Application Error" message
  - "Restart and recover from last save" option
- [ ] Restart app
- [ ] Verify last saved state restored

## Pass/Fail Criteria

### Critical (Must Pass)
- [ ] All canvas types render correctly (FSA, PDA, TM)
- [ ] No buttons blocked by layout (any screen size)
- [ ] Error widgets display and function (ErrorBanner, ImportErrorDialog, RetryButton)
- [ ] Touch gestures work without conflicts
- [ ] Performance ≥60fps with 20 states, 50 transitions
- [ ] Responsive layouts work (mobile, tablet, desktop)

### Important (Should Pass)
- [ ] Trace visualization accurate
- [ ] Accessibility labels present
- [ ] Touch targets ≥44x44px
- [ ] Manual save workflow functional
- [ ] Unsaved work indicator visible

### Nice to Have
- [ ] Keyboard navigation (desktop)
- [ ] Screen reader full compatibility
- [ ] Performance with 100+ states

## Troubleshooting

### Issue: Canvas not rendering
- Check console for errors
- Verify AutomatonCanvas widget present
- Check CustomPaint hierarchy (use Flutter Inspector)

### Issue: Buttons blocked
- Resize window to different breakpoints
- Check Stack/Positioned widget conflicts
- Verify z-index/layer ordering

### Issue: Gestures not working
- Check TouchGestureHandler initialization
- Verify no conflicting GestureDetectors
- Enable gesture debugging: `debugPaintPointersEnabled = true`

### Issue: Performance <60fps
- Check viewport culling enabled
- Verify LOD implementation
- Profile with Flutter DevTools Performance tab

## Reporting Issues

### Bug Report Template
```
**Title**: [Component] Brief description

**Steps to Reproduce**:
1. ...
2. ...

**Expected**: ...

**Actual**: ...

**Screenshots**: (attach)

**Device**: iOS 16 / Android 13 / macOS / Web

**Screen Size**: 375x667 / 768x1024 / 1280x800

**Build**: git commit hash
```

### Attach
- Screenshots showing issue
- Video recording (for gesture/animation issues)
- Flutter logs (if crash/error)

---
**Quickstart Complete**: Use this workflow for manual UI validation

