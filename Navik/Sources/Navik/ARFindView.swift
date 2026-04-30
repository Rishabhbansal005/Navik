import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Find View
struct ARFindView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var hapticsManager: HapticsManager

    let item: ItemModel
    @StateObject private var vm = ARFindViewModel()

    var room: RoomModel? { dataStore.room(for: item) }

    var body: some View {
        ZStack {
            ARFindContainer(viewModel: vm, item: item).ignoresSafeArea()

            if !vm.isRelocalized {
                RelocalizingOverlay(message: vm.relocMessage)
            } else {
                navigationHUD
            }
        }
        .onDisappear { vm.cleanup() }
        .onChange(of: vm.distance) { _, d in
            hapticsManager.pulse(distance: d)
        }
        .onChange(of: vm.itemReached) { _, reached in
            if reached { hapticsManager.playSuccess() }
        }
    }

    // MARK: Navigation HUD
    private var navigationHUD: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()

            if vm.itemReached {
                FoundOverlay(itemName: item.name, locationHint: item.locationDescription)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                VStack(spacing: 16) {
                    // Off-screen indicator
                    if vm.isOffScreen {
                        offScreenBanner
                    }
                    compassPanel
                }
                .padding(.bottom, AppTheme.xxl)
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.4), value: vm.itemReached)
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack(alignment: .top) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Item info chip
            HStack(spacing: 8) {
                if let emoji = item.emoji {
                    Text(emoji).font(.navBody)
                } else {
                    Image(systemName: item.iconName)
                        .font(.navSubhead)
                        .foregroundStyle(AppTheme.primary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name).font(.navCallout.weight(.semibold)).foregroundStyle(.white)
                    if let room {
                        Text(room.name).font(.navCaption2).foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.radius))
        }
        .padding(.horizontal, AppTheme.md)
        .padding(.top, AppTheme.sm)
    }

    // MARK: Off-screen banner
    private var offScreenBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.turn.up.right")
                .font(.navSubhead.weight(.semibold))
                .foregroundStyle(AppTheme.warning)
            Text("Item is off screen — follow the arrow")
                .font(.navCaption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Compass Panel
    private var compassPanel: some View {
        VStack(spacing: 18) {
            // Compass arrow
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    .frame(width: 110, height: 110)

                // Distance-coloured ring
                Circle()
                    .stroke(distanceColor, lineWidth: 3)
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 0.5), value: vm.distance)

                // Arrow
                Image(systemName: "location.north.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .rotationEffect(.radians(Double(vm.bearing)))
                    .animation(.interpolatingSpring(stiffness: 80, damping: 12), value: vm.bearing)
            }
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 12)

            // Distance label
            VStack(spacing: 4) {
                Text(formattedDistance)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: vm.distance)

                Text("to your item")
                    .font(.navCaption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Proximity bar
            ProximityBar(distance: vm.distance)
        }
        .padding(.horizontal, AppTheme.lg)
        .padding(.vertical, AppTheme.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .padding(.horizontal, AppTheme.xl)
    }

    private var distanceColor: Color {
        switch vm.distance {
        case 0..<NavConstants.veryCloseThreshold:  return AppTheme.success
        case NavConstants.veryCloseThreshold..<NavConstants.closeThreshold: return AppTheme.warning
        default: return AppTheme.primary
        }
    }

    private var formattedDistance: String {
        vm.distance < 1
            ? String(format: "%.0f cm", vm.distance * 100)
            : String(format: "%.1f m",  vm.distance)
    }
}

// MARK: - Proximity Bar
struct ProximityBar: View {
    let distance: Float
    private let maxDist: Float = 10.0
    var progress: Float { max(0, min(1, 1 - distance / maxDist)) }
    var color: Color {
        distance < NavConstants.veryCloseThreshold ? AppTheme.success
        : distance < NavConstants.closeThreshold   ? AppTheme.warning
        : AppTheme.primary
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15)).frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Far").font(.navCaption2).foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text("Close").font(.navCaption2).foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(width: 180)
    }
}

// MARK: - Relocalizing Overlay
struct RelocalizingOverlay: View {
    let message: String
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(spacing: 8) {
                    Text("Locating Item").font(.navTitle3).foregroundStyle(.white)
                    Text(message)
                        .font(.navCallout).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}

// MARK: - Found Overlay
struct FoundOverlay: View {
    let itemName: String
    let locationHint: String
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .opacity(pulse ? 0 : 0.6)
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.success)
                    .symbolEffect(.bounce)
            }
            .onAppear { pulse = true }

            VStack(spacing: 6) {
                Text("You found it! 🎉").font(.navTitle2).foregroundStyle(.white)
                Text(itemName).font(.navHeadline).foregroundStyle(AppTheme.accent)
                if !locationHint.isEmpty {
                    Text(locationHint).font(.navCallout).foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(.horizontal, AppTheme.lg).padding(.vertical, AppTheme.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .padding(.horizontal, AppTheme.xl)
        .padding(.bottom, AppTheme.xxl)
    }
}

// MARK: - AR Container
struct ARFindContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARFindViewModel
    let item: ItemModel

    func makeUIView(context: Context) -> ARView {
        let v = ARView(frame: .zero)
        v.renderOptions = [.disableMotionBlur]
        viewModel.setup(v, item: item)
        return v
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview("Relocalizing") {
    RelocalizingOverlay(message: "Scan the area where you saved this item…")
}

#Preview("Found") {
    ZStack {
        Color.black.ignoresSafeArea()
        FoundOverlay(itemName: "Car Keys", locationHint: "Kitchen drawer")
    }
}
