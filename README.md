# 🧭 Navik — Never Lose Track of Your Things

> An intelligent AR-powered item tracker for people who face memory challenges.  
> Built with **SwiftUI**, **ARKit**, and **LiDAR** — exclusively for iPhone.

---

## 📖 About

**Navik** is an iOS application designed to help people with memory challenges remember where they placed their everyday items — like medicines, keys, glasses, or wallets.

Instead of searching your entire home, Navik uses **Augmented Reality** and **Apple's LiDAR sensor** to precisely save the real-world location of an item. When you need to find it later, the app guides you back with a **live AR directional arrow** and **haptic feedback** that intensifies as you get closer.

---

## 🎥 Demo

[![Navik App Demo](https://img.youtube.com/vi/CWtFoZM_KBs/maxresdefault.jpg)](https://www.youtube.com/watch?v=CWtFoZM_KBs)

> ⚠️ *This demo shows an earlier version of Navik. The current version includes improved AR navigation, haptic feedback, and a redesigned room management system. *

---

## ✨ Features

### 📦 Item Tab
- Add items with a custom **name** (e.g., "Medicines", "Keys")
- Choose a **shelf/surface** and **room** where the item is placed
- Select a **symbol/icon** to represent the item visually
- Save the item's exact location using the **built-in AR camera with a placement marker**
- The location is stored using **ARKit + LiDAR spatial anchors** — no manual input needed

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
| **LiDAR Scanner** | Precise depth sensing & room mapping |
| **RealityKit** | 3D arrow rendering in AR |
| **Core Haptics** | Proximity-based haptic feedback |
| **Core Data / SwiftData** | Persistent storage of items & rooms |

---

## 📱 Device Requirements

> ⚠️ **Navik requires an iPhone with a LiDAR Scanner.**  
> This is a hardware limitation — LiDAR is the core technology that makes precise item tracking possible.

| Device | Compatible |
|---|---|
| iPhone 12 Pro / Pro Max | ✅ |
| iPhone 13 Pro / Pro Max | ✅ |
| iPhone 14 Pro / Pro Max | ✅ |
| iPhone 15 Pro / Pro Max | ✅ |
| iPhone 16 Pro / Pro Max | ✅ |
| iPhone 12 / 13 / 14 / 15 / 16 (standard) | ❌ No LiDAR |
| iPhone SE (any generation) | ❌ No LiDAR |
| iPad Pro (2020 and later) | ✅ |

**Software:**
- iOS 16.0 or later
- Xcode 15+ (to build from source)
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

> ⚠️ **LiDAR and ARKit features do not work on the iOS Simulator.**  
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
    │   └── ARSessionManager.swift # Handles ARKit session & LiDAR anchors
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
        │               └── LiDAR captures real-world coordinates
        │                   and stores a spatial anchor
        │
        └── Tap a saved item anytime
                │
                ├── AR launches → 3D arrow points to item's location
                └── Haptics pulse faster as you get closer ✅
```


> *"Navik" (नाविक) — meaning Navigator in Hindi. Your personal guide to finding what matters.*
