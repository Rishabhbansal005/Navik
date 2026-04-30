import SwiftUI

// MARK: - App Entry Point
@main
struct NavikApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var dataStore      = DataStore()
    @StateObject private var hapticsManager = HapticsManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    NavikTabView()
                        .environmentObject(dataStore)
                        .environmentObject(hapticsManager)
                } else {
                    OnboardingView()
                        .environmentObject(dataStore)
                        .environmentObject(hapticsManager)
                }
            }
            .tint(AppTheme.primary)
        }
    }
}

// MARK: - Main Tab View
struct NavikTabView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var hapticsManager: HapticsManager

    var body: some View {
        TabView {
            Tab("Items", systemImage: "cube.box.fill") {
                ItemsView()
            }
            Tab("Rooms", systemImage: "door.left.hand.open") {
                RoomsView()
            }
        }
        .tint(AppTheme.primary)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    NavikTabView()
        .environmentObject(DataStore())
        .environmentObject(HapticsManager())
}
