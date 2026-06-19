# 🧭 Navik — Never Lose Track of Your Things

> An intelligent AR-powered item tracker for people who face memory challenges.  
> Built with **SwiftUI**, **ARKit**, and **LiDAR** — works on all modern iPhones.

---

## 📖 About

**Navik** is an iOS application designed to help people with memory challenges remember where they placed their everyday items — like medicines, keys, glasses, or wallets.

Instead of searching your entire home, Navik uses **Augmented Reality** to precisely save the real-world location of an item. When you need to find it later, the app guides you back to it with real-time AR navigation and haptic feedback.

---

## 🎥 Demo

[![Navik App Demo](https://img.youtube.com/vi/CWtFoZM_KBs/maxresdefault.jpg)](https://www.youtube.com/watch?v=CWtFoZM_KBs)

> ⚠️ *This demo shows an earlier version of Navik. The current version includes improved AR navigation, fixed AR models, and now works on all iPhone models with varying accuracy levels.*

---

## ✨ Features

### 📦 Item Tab
- Add items with a custom **name** (e.g., "Medicines", "Keys")
- Choose a **shelf/surface** and **room** where the item is placed
- Select a **symbol/icon** to represent the item visually
- Save the item's exact location using the **built-in AR camera with a placement marker**
- The location is stored using **ARKit spatial anchors** — no manual input needed

### 🔍 AR Navigation
- Tap any saved item to launch **real-time AR guidance**
- A **3D directional arrow** points you toward the item within the room
- **Haptic feedback** pulses faster as you get physically closer to the item
- Works indoors across rooms

### 🏠 Room Tab
- Create and manage custom **rooms** (e.g., Bedroom, Kitchen, Study)
- Rooms are reusable — simply select a room whenever saving an item's location

---

## 🛠 Tech Stack

| Technology | Purpose |
|---|---|
| **SwiftUI** | UI framework |
| **ARKit** | Augmented Reality & spatial tracking |
| **LiDAR Scanner** | Enhanced depth sensing (Pro models) |
| **RealityKit** | 3D arrow rendering in AR |
| **Core Haptics** | Proximity-based haptic feedback |
| **Core Data / SwiftData** | Persistent storage of items & rooms |

---

## 📱 Device Requirements

### ✅ Fully Supported (High Accuracy)
**iPhones with LiDAR Scanner** provide the best accuracy:

| Device | Compatible | Accuracy |
|---|---|---|
| iPhone 12 Pro / Pro Max | ✅ | High (LiDAR) |
| iPhone 13 Pro / Pro Max | ✅ | High (LiDAR) |
| iPhone 14 Pro / Pro Max | ✅ | High (LiDAR) |
| iPhone 15 Pro / Pro Max | ✅ | High (LiDAR) |
| iPhone 16 Pro / Pro Max | ✅ | High (LiDAR) |
| iPad Pro (2020 and later) | ✅ | High (LiDAR) |

### ⚠️ Supported (Lower Accuracy)
**Standard iPhones without LiDAR** now supported with reduced accuracy:

| Device | Compatible | Accuracy |
|---|---|---|
| iPhone 12 / 13 / 14 / 15 / 16 (standard) | ✅ | Low (ARKit only) |
| iPhone SE (any generation) | ✅ | Low (ARKit only) |

**Important Notes:**
- **Pro models with LiDAR** provide precise depth sensing for highly accurate item tracking
- **Standard models without LiDAR** use ARKit's visual tracking, resulting in lower accuracy but still functional
- Accuracy may vary based on lighting conditions, room layout, and surface features
- iOS 16.0 or later required
- Xcode 15+ required to build from source
- Camera & Motion permissions required at runtime

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Rishabhbansal005/Navik.git
cd Navik
```

### 2. Open in Xcode

```bash
open Navik.xcodeproj
```

### 3. Set Your Development Team

- Go to **Xcode → Navik target → Signing & Capabilities**
- Select your **Apple Developer account** under Team

### 4. Run on a Physical Device

> ⚠️ **ARKit features do not work on the iOS Simulator.**  
> Connect a supported iPhone and run directly on device.

---

## 📂 Project Structure

```
Navik/
├── Navik.xcodeproj/          # Xcode project configuration
└── Navik/
    ├── App/
    │   └── NavikApp.swift         # App entry point
    ├── Views/
    │   ├── ItemTab/               # Item listing & item detail views
    │   ├── RoomTab/               # Room management views
    │   └── AR/                    # AR camera & navigation views
    ├── Models/
    │   ├── Item.swift             # Item data model
    │   └── Room.swift             # Room data model
    ├── ViewModels/
    │   ├── ItemViewModel.swift
    │   └── RoomViewModel.swift
    ├── ARManager/
    │   └── ARSessionManager.swift # Handles ARKit session & spatial tracking
    ├── HapticsManager/
    │   └── HapticsManager.swift   # Core Haptics proximity logic
    └── Assets.xcassets/           # App icons, symbols, colors
```

---

## 🗺 How It Works

```
User opens Navik
        │
        ▼
   [ Item Tab ]
        │
        ├── Tap "+" to add a new item
        │       │
        │       ├── Enter item name (e.g., "Medicines")
        │       ├── Select shelf/surface
        │       ├── Select room
        │       ├── Choose a symbol
        │       └── Camera opens → place item in AR marker → Save
        │               │
        │               └── ARKit captures spatial coordinates
        │                   (LiDAR on Pro models for higher accuracy)
        │
        └── Tap a saved item anytime
                │
                ├── AR launches → 3D arrow points to item's location
                └── Haptics pulse faster as you get closer ✅
```

---

## 📝 Recent Changes

### v1.2 - Extended Device Support
- ✅ Added support for non-Pro iPhone models (iPhone 12-16, SE)
- ✅ Fixed AR model rendering issues
- ✅ Implemented accuracy warnings for non-LiDAR devices
- ✅ Enhanced spatial tracking for standard cameras

### v1.1 - Initial Release
- Added AR-based item tracking with LiDAR support
- Implemented haptic feedback proximity detection
- Room management system

---

## 🎯 Accuracy Levels

| Device Type | Technology | Typical Range | Ideal Use Case |
|---|---|---|---|
| **Pro with LiDAR** | LiDAR + ARKit | Up to 99% | Daily use, precise tracking |
| **Standard iPhone** | ARKit Visual Tracking | 70-85% | General use, well-lit areas |

**Tips for better accuracy on standard models:**
- Use in well-lit environments with visible features
- Allow the app a moment to calibrate the AR scene
- Avoid blank walls or uniformly-textured surfaces
- Keep the device steady when placing items

---

> *"Navik" (नाविक) — meaning Navigator in Hindi. Your personal guide to finding what matters.*
