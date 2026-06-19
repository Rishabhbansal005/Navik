import ARKit
import RealityKit
import Combine

// MARK: - AR Save ViewModel
final class ARSaveViewModel: NSObject, ObservableObject, @unchecked Sendable {
    // Published state for UI
    @Published var trackingQuality: TrackingQuality = .unavailable
    @Published var trackingMessage  = "Initialising AR…"
    @Published var qualityDots      = 0                   // 0-5
    @Published var qualityLabel     = "Scanning…"
    @Published var canSave          = false
    @Published var featureCount     = 0
    @Published var planeCount       = 0
    @Published var isLiDARAvailable = false
    @Published var scanProgress: Float = 0                // 0-1 for onboarding ring

    // Data for ItemModel
    var currentTransform: simd_float4x4?
    var worldMapData: Data?

    private var session: ARSession?
    private var arDelegate: ARSaveDelegateHandler?

    // LiDAR availability check
    static var deviceSupportsLiDAR: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    func setupSession(_ session: ARSession) {
        self.session = session

        let delegate = ARSaveDelegateHandler(viewModel: self)
        self.arDelegate = delegate
        session.delegate = delegate

        Task { @MainActor in
            self.isLiDARAvailable = Self.deviceSupportsLiDAR
        }
    }

    func cleanup() {
        session?.pause()
        session?.delegate = nil
        arDelegate = nil
        session = nil
    }

    // Called on main thread by delegate
    func applyFrame(transform: simd_float4x4,
                    trackingState: ARCamera.TrackingState,
                    features: Int,
                    planes: Int) {
        currentTransform = transform
        featureCount     = features
        planeCount       = planes
        updateTracking(trackingState, features: features, planes: planes)
    }

    private func updateTracking(_ state: ARCamera.TrackingState, features: Int, planes: Int) {
        switch state {
        case .normal:
            trackingMessage = isLiDARAvailable ? "Ready to save" : "Ready — scan more surfaces for best accuracy"
            let quality = computeQuality(features: features, planes: planes)
            applyQuality(quality)
        case .limited(.initializing):
            trackingMessage  = "Scanning environment…"
            trackingQuality  = .poor
            qualityDots      = 1
            qualityLabel     = "Initialising"
            canSave          = false
            scanProgress     = 0.1
        case .limited(.insufficientFeatures):
            trackingMessage  = isLiDARAvailable ? "Point at a textured surface" : "Point at furniture or a wall"
            trackingQuality  = .poor
            qualityDots      = 1
            qualityLabel     = "Need more detail"
            canSave          = false
        case .limited(.excessiveMotion):
            trackingMessage  = "Move slower"
            trackingQuality  = .fair
            qualityDots      = 2
            qualityLabel     = "Too fast"
            canSave          = false
        case .limited(.relocalizing):
            trackingMessage  = "Relocating…"
            trackingQuality  = .fair
            qualityDots      = 2
            qualityLabel     = "Relocating"
            canSave          = false
        case .notAvailable:
            trackingMessage  = "AR unavailable"
            trackingQuality  = .unavailable
            qualityDots      = 0
            qualityLabel     = "Unavailable"
            canSave          = false
        @unknown default:
            break
        }
    }

    private func computeQuality(features: Int, planes: Int) -> Float {
        var q: Float = 0

        if isLiDARAvailable {
            // LiDAR devices: mesh reconstruction supplements feature matching,
            // so fewer raw features are needed for a high quality reading.
            if      features > 2000 { q += 0.45 }
            else if features > 1000 { q += 0.35 }
            else if features > 400  { q += 0.20 }
            else                    { q += 0.05 }
            if planes >= 2 { q += 0.30 } else if planes >= 1 { q += 0.18 }
            q += 0.25   // LiDAR mesh bonus
        } else {
            // Non-LiDAR devices: rely purely on visual feature points & planes.
            // Thresholds are tuned so a normal indoor scan on iPhone 14 reaches
            // "Good" (0.55+) after ~10s of slow scanning.
            if      features > 3000 { q += 0.50 }
            else if features > 1500 { q += 0.42 }
            else if features > 600  { q += 0.32 }
            else if features > 200  { q += 0.15 }
            else                    { q += 0.04 }
            if planes >= 2 { q += 0.35 } else if planes >= 1 { q += 0.22 }
            // 600 features + 1 plane = 0.54  → borderline Good
            // 1500 features + 1 plane = 0.64 → Good ✓
        }

        return min(q, 1.0)
    }

    private func applyQuality(_ q: Float) {
        scanProgress = q
        // On non-LiDAR devices the max achievable score is ~0.85 (no mesh bonus).
        // We therefore allow saving at "Fair" (0.38+) so the button is never
        // permanently blocked on iPhone 14 and similar devices.
        let saveThreshold: Float = isLiDARAvailable ? 0.55 : 0.38
        switch q {
        case let x where x >= 0.90:
            trackingQuality = .excellent; qualityDots = 5; qualityLabel = "Excellent"
        case let x where x >= 0.72:
            trackingQuality = .good;      qualityDots = 4; qualityLabel = "Very Good"
        case let x where x >= 0.55:
            trackingQuality = .good;      qualityDots = 3; qualityLabel = "Good"
        case let x where x >= 0.38:
            trackingQuality = .fair;      qualityDots = 2; qualityLabel = "Fair"
        default:
            trackingQuality = .poor;      qualityDots = 1; qualityLabel = "Poor"
        }
        canSave = q >= saveThreshold
    }

    func updateWorldMap(data: Data) {
        worldMapData = data
    }
}

// MARK: - Delegate handler (separate NSObject for Swift 6 Sendable safety)
final class ARSaveDelegateHandler: NSObject, ARSessionDelegate, @unchecked Sendable {
    private weak var viewModel: ARSaveViewModel?

    init(viewModel: ARSaveViewModel) { self.viewModel = viewModel }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform  = frame.camera.transform
        let state      = frame.camera.trackingState
        let features   = frame.rawFeaturePoints?.points.count ?? 0
        let planes     = frame.anchors.compactMap { $0 as? ARPlaneAnchor }.count

        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.applyFrame(transform: transform, trackingState: state,
                                       features: features, planes: planes)
        }

        // Capture world map every ~2s
        session.getCurrentWorldMap { [weak self] map, _ in
            guard let map,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
            else { return }
            DispatchQueue.main.async { self?.viewModel?.updateWorldMap(data: data) }
        }
    }
}
