import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Save View
struct ARSaveView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore

    let itemName:            String
    let roomID:              UUID
    let iconName:            String
    let emoji:               String?
    let photoData:           Data?
    let locationDescription: String

    @StateObject private var vm = ARSaveViewModel()
    @State private var saved      = false
    @State private var showGuide  = true

    var body: some View {
        ZStack {
            // AR camera feed
            ARSaveContainer(viewModel: vm).ignoresSafeArea()

            // Scanning guide overlay (shown initially)
            if showGuide {
                ScanGuideOverlay {
                    withAnimation(.easeOut(duration: 0.4)) { showGuide = false }
                }
                .transition(.opacity)
            } else {
                // Main AR HUD
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if !saved { centerContent }
                    Spacer()
                    if !saved { bottomPanel }
                }
            }

            // Success overlay
            if saved {
                SaveSuccessOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .onDisappear { vm.cleanup() }
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

            // Tracking status chip
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.trackingQuality.color)
                    .frame(width: 8, height: 8)
                Text(vm.trackingMessage)
                    .font(.navCaption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, AppTheme.md)
        .padding(.top, AppTheme.sm)
    }

    // MARK: Center crosshair + quality ring
    private var centerContent: some View {
        VStack(spacing: 20) {
            // Scanning quality ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: CGFloat(vm.scanProgress))
                    .stroke(vm.trackingQuality.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: vm.scanProgress)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(.white)
            }

            // LiDAR badge
            if vm.isLiDARAvailable {
                Label("LiDAR Active", systemImage: "sensor.tag.radiowaves.forward.fill")
                    .font(.navCaption2.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
            }
        }
    }

    // MARK: Bottom Panel
    private var bottomPanel: some View {
        VStack(spacing: 14) {
            // Quality dots
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < vm.qualityDots ? vm.trackingQuality.color : Color.white.opacity(0.25))
                        .frame(width: i < vm.qualityDots ? 20 : 8, height: 6)
                        .animation(.spring(duration: 0.35), value: vm.qualityDots)
                }
                Text(vm.qualityLabel)
                    .font(.navCaption.weight(.semibold))
                    .foregroundStyle(.white)
                    .animation(.none, value: vm.qualityLabel)
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())

            // Info row
            HStack(spacing: 12) {
                infoChip("\(vm.featureCount)", icon: "point.3.filled.connected.trianglepath.dotted", label: "features")
                infoChip("\(vm.planeCount)",   icon: "square.3.layers.3d",                           label: "planes")
            }

            // Save button
            Button { performSave() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill").font(.title3)
                    Text("Save Location").font(.navHeadline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    vm.canSave ? AppTheme.primary : Color.white.opacity(0.2),
                    in: RoundedRectangle(cornerRadius: AppTheme.radius)
                )
            }
            .disabled(!vm.canSave)
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.25), value: vm.canSave)
        }
        .padding(.horizontal, AppTheme.md)
        .padding(.bottom, AppTheme.xl)
        .padding(.top, AppTheme.sm)
    }

    private func infoChip(_ value: String, icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.navCaption2)
            Text("\(value) \(label)").font(.navCaption2)
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: Save action
    private func performSave() {
        guard let transform = vm.currentTransform else { return }
        let item = ItemModel(
            name: itemName, roomID: roomID, iconName: iconName,
            emoji: emoji, imageData: photoData,
            locationDescription: locationDescription,
            anchorTransform: transform,
            worldMapData: vm.worldMapData,
            saveQuality: vm.scanProgress
        )
        dataStore.addItem(item)
        withAnimation(.spring(duration: 0.45)) { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            vm.cleanup(); dismiss()
        }
    }
}

// MARK: - Scan Guide Overlay
struct ScanGuideOverlay: View {
    let onStart: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    ForEach([0.6, 0.75, 0.9, 1.0], id: \.self) { scale in
                        Circle()
                            .stroke(AppTheme.primary.opacity(0.15 * scale), lineWidth: 1.5)
                            .frame(width: 140 * scale, height: 140 * scale)
                            .scaleEffect(pulse ? 1.08 : 1.0)
                    }
                    Image(systemName: "sensor.tag.radiowaves.forward.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.primary)
                        .symbolEffect(.pulse)
                }
                .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true } }

                VStack(spacing: 10) {
                    Text("Scan Your Environment").font(.navTitle2).foregroundStyle(.white)
                    Text("Move your phone slowly around the area\nwhere you want to save this item's location.")
                        .font(.navCallout).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center).lineSpacing(4)
                }

                VStack(spacing: 12) {
                    guideStep("1", text: "Slowly move your phone around the area")
                    guideStep("2", text: "Include floor, walls, and furniture")
                    guideStep("3", text: "Wait for quality to reach Good or better")
                }
                .padding(.horizontal, AppTheme.xl)

                Spacer()

                Button(action: onStart) {
                    Text("Start Scanning")
                        .font(.navHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: AppTheme.radius))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppTheme.xl)
                .padding(.bottom, AppTheme.xxl)
            }
        }
    }

    private func guideStep(_ num: String, text: String) -> some View {
        HStack(spacing: 14) {
            Text(num)
                .font(.navCaption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.primary, in: Circle())
            Text(text).font(.navBody).foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }
}

// MARK: - Save Success Overlay
struct SaveSuccessOverlay: View {
    @State private var scale = 0.6
    var body: some View {
        Color.black.opacity(0.4).ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(AppTheme.success)
                        .symbolEffect(.bounce)
                    Text("Location Saved!")
                        .font(.navTitle2).foregroundStyle(.white)
                    Text("You can now find this item using AR navigation.")
                        .font(.navCallout).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                    ProgressView().tint(AppTheme.accent).padding(.top, 4)
                }
                .padding(40)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                .padding(AppTheme.xl)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.spring(duration: 0.45, bounce: 0.3)) { scale = 1.0 }
                }
            )
    }
}

// MARK: - AR Container
struct ARSaveContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARSaveViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection       = [.horizontal, .vertical]
        config.worldAlignment       = .gravity
        config.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        arView.renderOptions = [.disableMotionBlur, .disableDepthOfField]
        arView.session.run(config)
        viewModel.setupSession(arView.session)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview("AR Save Guide") {
    ScanGuideOverlay { }
}
