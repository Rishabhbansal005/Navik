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
            trackingMessage = "Ready to save"
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
            trackingMessage  = "Point at a textured surface"
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
        if      features > 3000 { q += 0.4 }
        else if features > 1500 { q += 0.3 }
        else if features > 500  { q += 0.2 }
        else                    { q += 0.05 }
        if planes >= 2 { q += 0.35 } else if planes >= 1 { q += 0.2 }
        if isLiDARAvailable  { q += 0.25 }  // LiDAR bonus
        return min(q, 1.0)
    }

    private func applyQuality(_ q: Float) {
        scanProgress = q
        switch q {
        case let x where x >= 0.90:
            trackingQuality = .excellent; qualityDots = 5; qualityLabel = "Excellent"; canSave = true
        case let x where x >= 0.72:
            trackingQuality = .good;      qualityDots = 4; qualityLabel = "Very Good";  canSave = true
        case let x where x >= 0.55:
            trackingQuality = .good;      qualityDots = 3; qualityLabel = "Good";       canSave = true
        case let x where x >= 0.35:
            trackingQuality = .fair;      qualityDots = 2; qualityLabel = "Fair";       canSave = false
        default:
            trackingQuality = .poor;      qualityDots = 1; qualityLabel = "Poor";       canSave = false
        }
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
