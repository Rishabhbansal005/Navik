# Navik — AR Item Finder
### Swift Student Challenge 2025 · iOS 26 · Liquid Glass

> Never lose track of your belongings again. Navik uses ARKit to save the exact real‑world location of your items and guides you back to them with an AR compass.

---

## ✨ iOS 26 Features Used

| Feature | Where |
|---|---|
| `glassEffect(.regular)` | All AR overlays, onboarding icons, compass |
| `GlassEffectContainer` | Every floating HUD panel |
| `glassEffectID` + matched geometry | Save/Find AR bottom controls |
| `.buttonStyle(.glass)` | Toolbar + buttons |
| `.buttonStyle(.glassProminent)` | Save Location, Get Started, Photo Pick |
| `tabBarMinimizeBehavior(.onScrollDown)` | Tab bar auto‑hide on scroll |
| `Tab { }` (new TabView syntax) | Main navigation |
| `navigationTransition(.zoom(...))` | Add Item / Add Room sheets |
| `searchToolbarBehavior(.minimize)` | Items search bar |
| `.symbolEffect(.breathe)` | Onboarding icons |
| `.symbolEffect(.bounce)` | Found‑item checkmark |
| `.contentTransition(.numericText())` | Live distance counter |
| `@MainActor` on classes | DataStore, HapticsManager, ViewModels |
| Swift 6 strict concurrency | All files |

---

## Requirements

| | |
|---|---|
| **Xcode** | 26 beta (or later) |
| **iOS Deployment Target** | 26.0 |
| **Swift** | 6.0 |
| **Device** | iPhone or iPad with ARKit support |

> ⚠️ ARKit requires a **physical device**. The Simulator does not support ARKit or most Liquid Glass effects at full fidelity.

---

## Getting Started

```bash
# 1. Clone / download
git clone https://github.com/yourname/Navik.git

# 2. Open project
open Navik.xcodeproj
```

3. Select **Navik** target → **Signing & Capabilities** → set your **Team**
4. Connect your iPhone running **iOS 26**
5. Press **⌘R**

---

## Project Structure

```
Navik/
├── Navik.xcodeproj/
└── Navik/
    ├── Sources/Navik/
    │   ├── MyApp.swift               # @main entry point
    │   ├── AppTheme.swift            # Design tokens, Font extensions
    │   ├── Theme.swift               # Constants, simd extensions
    │   ├── DataStore.swift           # @MainActor persistence
    │   ├── RoomModel.swift
    │   ├── ItemModel.swift           # simd_float4x4 Codable wrapper
    │   ├── HapticsManager.swift      # CoreHaptics proximity buzz
    │   ├── OnboardingView.swift      # Liquid Glass 4‑page intro
    │   ├── NavikTabView.swift        # iOS 26 Tab { } syntax
    │   ├── ItemsView.swift           # Items list + search
    │   ├── RoomsView.swift           # Rooms CRUD
    │   ├── AddItemView.swift         # Symbol / Emoji / Photo icon picker
    │   ├── ARSaveView.swift          # ARKit save with quality meter
    │   ├── ARFindView.swift          # AR compass navigator
    │   └── SettingsView.swift        # Haptics toggle, stats, reset
    └── Resources/
        ├── Assets.xcassets/          # AppIcon + AccentColor
        └── Info.plist                # Camera + Motion permissions
```

---

## How It Works

1. **Save** — Open Add Item, fill in name + room, tap **Next** → ARKit scans the environment, builds a world map, and saves the item's `simd_float4x4` transform + `ARWorldMap` to `UserDefaults`.

2. **Find** — Tap any item in the list → `ARFindView` loads the saved `ARWorldMap`, relocalises, and shows a rotating arrow + live distance counter. CoreHaptics pulses get faster as you get closer.

---

## Frameworks

- **SwiftUI** — all UI, iOS 26 Liquid Glass APIs
- **ARKit** — world tracking, world maps, relocalization
- **RealityKit** — AR view rendering
- **CoreHaptics** — proximity-based haptic feedback
- **PhotosUI** — photo picker for item icons

---

## Privacy

All data is stored **locally on‑device** using `UserDefaults`. Nothing is sent to any server.

Permissions requested:
- **Camera** — AR saving and finding
- **Motion** — AR tracking accuracy

---

*Built with ❤️ for the Apple Swift Student Challenge 2025*
