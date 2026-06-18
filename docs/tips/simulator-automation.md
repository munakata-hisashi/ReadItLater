# Simulator CLI / UI Automation Notes

This memo summarizes the knowledge and commands used to control iOS Simulator from the CLI and to automate basic UI interactions for screenshots.

## 1) Simulator device management (simctl)

List devices:
```sh
xcrun simctl list devices
```

Boot a device (by name):
```sh
xcrun simctl boot "iPhone 17"
```

Open the Simulator app UI:
```sh
open -a Simulator
```

## 2) Build, install, and launch the app

Build (keep DerivedData inside the repo):
```sh
xcodebuild \
  -project ReadItLater.xcodeproj \
  -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -derivedDataPath .derivedData \
  build
```

Install to the booted simulator:
```sh
xcrun simctl install booted \
  .derivedData/Build/Products/Debug-iphonesimulator/ReadItLater.app
```

Launch by bundle id:
```sh
xcrun simctl launch booted munakata-hisashi.ReadItLater
```

## 3) Screenshot

```sh
xcrun simctl io booted screenshot /tmp/readitlater_sim.png
```

## 4) UI automation: limitations

- `simctl` does not support tap/drag. It only supports screenshot and record operations.
- For real UI interactions, use macOS Accessibility with AppleScript or CGEvent.

## 5) AppleScript: window position/size and clicks

Enable **Accessibility** for the Terminal/CLI app before running these.

Get window names:
```applescript
tell application "System Events" to tell process "Simulator" to get name of windows
```

Get window position/size:
```applescript
tell application "System Events" to tell process "Simulator" to get position of window 1
tell application "System Events" to tell process "Simulator" to get size of window 1
```

Click the tab bar (example uses window 1):
```applescript
tell application "System Events" to tell process "Simulator" to set frontmost to true
set x1 to item 1 of (position of window 1)
set y1 to item 2 of (position of window 1)
set w to item 1 of (size of window 1)
set h to item 2 of (size of window 1)
-- Tap the Archive tab (approx 83% width)
tell application "System Events" to click at {x1 + (w * 0.83), y1 + h - 40}
```

## 6) CGEvent: drag to reveal swipe actions

Small swipes avoid full-swipe actions. The coordinates below assume:
- window position: (1060, 33)
- window size: (435, 929)

Adjust if your Simulator window differs.

```swift
import Cocoa
import Foundation

func post(_ type: CGEventType, _ point: CGPoint) {
    guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }
    event.post(tap: .cghidEventTap)
}

func drag(from: CGPoint, to: CGPoint, steps: Int = 10) {
    post(.leftMouseDown, from)
    usleep(50_000)
    for i in 1...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let x = from.x + (to.x - from.x) * t
        let y = from.y + (to.y - from.y) * t
        post(.leftMouseDragged, CGPoint(x: x, y: y))
        usleep(20_000)
    }
    post(.leftMouseUp, to)
}

// Small leading swipe (left -> right)
let start = CGPoint(x: 1145, y: 285)
let end   = CGPoint(x: 1215, y: 285)

drag(from: start, to: end)
```

Run it:
```sh
swift /path/to/drag.swift
```

## 7) Tips

- If you see full-swipe actions (e.g. auto-bookmark), reduce drag distance.
- If a drag fails, verify window position/size and adjust coordinates.
- Keep DerivedData inside the repo to avoid system-wide caches: `-derivedDataPath .derivedData`.
