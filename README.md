# Pomodoro for macOS

A native SwiftUI Pomodoro timer with a main window and a menu bar timer.

## Build & run

Requires macOS 14+ and the Swift toolchain (Command Line Tools are enough; Xcode is not required).

```bash
./build-app.sh
open build/Pomodoro.app
```

To install, drag `build/Pomodoro.app` into `/Applications`.

For quick development runs: `swift run` (notifications are disabled when not running as a bundled app).

## App icon

The tomato icon is drawn in code by `scripts/make-icon.swift`. `build-app.sh` regenerates `Resources/AppIcon.icns` whenever that script changes.

## Features

- Focus / Short Break / Long Break phases with a progress ring
- Automatic long break after N focus sessions
- Live countdown in the menu bar, with a mini control panel
- System notifications and sounds when a session ends
- Configurable durations, auto-start, and sound (Settings, ⌘,)
- Shortcuts: Space = start/pause, ⌘R = reset, ⇧⌘S = skip
