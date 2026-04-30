import ARKit
import RealityKit
import Combine
import UIKit

// MARK: - AR Find ViewModel
final class ARFindViewModel: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRelocalized    = false
    @Published var distance: Float  = 0
    @Published var bearing: Float   = 0
    @Published var isOffScreen      = false
    @Published var itemReached      = false
    @Published var trackingQuality: TrackingQuality = .unavailable
    @Published var relocMessage     = "Scan the area where you saved this item…"

    // Smoothed values (exponential moving average)
    private var smoothBearing:  Float = 0
    private var smoothDistance: Float = 0
    private var frameCount      = 0

    var arView: ARView?
    var targetTransform: simd_float4x4?
    private var arDelegate: ARFindDelegateHandler?

    @MainActor func setup(_ arView: ARView, item: ItemModel) {
        self.arView          = arView
        self.targetTransform = item.anchorTransform

        let config = ARWorldTrackingConfiguration()
        config.planeDetection       = [.horizontal, .vertical]
        config.worldAlignment       = .gravity
        config.environmentTexturing = .automatic

        // LiDAR occlusion
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .meshWithClassification
        }

        if let mapData = item.worldMapData,
           let map = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) {
            config.initialWorldMap = map
        }

        let d = ARFindDelegateHandler(viewModel: self)
        self.arDelegate = d
        arView.session.delegate = d

        // Enable LiDAR occlusion rendering
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            arView.environment.sceneUnderstanding.options = [.occlusion, .physics]
        }

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Navigation update (called every frame from delegate)
    @MainActor func updateNavigation(cameraTransform: simd_float4x4) {
        guard let target = targetTransform else { return }
        frameCount += 1

        let rawDist = cameraTransform.distance(to: target)
        let rawBear = cameraTransform.horizontalBearing(to: target)

        // Exponential moving average smoothing
        smoothDistance = smoothDistance * (1 - NavConstants.distanceSmoothing) + rawDist * NavConstants.distanceSmoothing
        smoothBearing  = lerpAngle(smoothBearing, rawBear, t: NavConstants.bearingSmoothing)

        distance    = smoothDistance
        bearing     = smoothBearing
        itemReached = smoothDistance < NavConstants.reachedThreshold
    }

    func applyTrackingState(_ state: ARCamera.TrackingState) {
        switch state {
        case .normal:
            trackingQuality = .excellent
            relocMessage    = "Follow the arrow to your item"
            // If we've reached normal tracking, we consider it relocalized (if a map was provided)
            DispatchQueue.main.async { [weak self] in
                self?.isRelocalized = true
            }
        case .limited(.relocalizing):
            trackingQuality = .fair
            relocMessage    = "Scanning… move around slowly"
        case .limited(.insufficientFeatures):
            trackingQuality = .poor
            relocMessage    = "Point at a textured surface"
        case .limited(.excessiveMotion):
            trackingQuality = .fair
            relocMessage    = "Slow down"
        default:
            trackingQuality = .unavailable
        }
    }

    @MainActor func cleanup() {
        arView?.session.pause()
        arView?.scene.anchors.removeAll()
        arView?.session.delegate = nil
        arDelegate = nil
        arView     = nil
    }
}

// MARK: - Angle lerp (handles wraparound)
private func lerpAngle(_ a: Float, _ b: Float, t: Float) -> Float {
    var diff = b - a
    while diff >  Float.pi { diff -= 2 * Float.pi }
    while diff < -Float.pi { diff += 2 * Float.pi }
    return a + diff * t
}

// MARK: - Delegate handler
final class ARFindDelegateHandler: NSObject, ARSessionDelegate, @unchecked Sendable {
    private weak var viewModel: ARFindViewModel?

    init(viewModel: ARFindViewModel) { self.viewModel = viewModel }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cam   = frame.camera.transform
        let state = frame.camera.trackingState
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.updateNavigation(cameraTransform: cam)
            self?.viewModel?.applyTrackingState(state)
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        if case .normal = camera.trackingState {
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.isRelocalized = true
            }
        }
    }
}
