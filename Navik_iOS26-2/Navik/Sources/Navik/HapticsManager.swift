import CoreHaptics
import UIKit

final class HapticsManager: ObservableObject, @unchecked Sendable {
    @Published var isEnabled = true

    private var engine: CHHapticEngine?
    private var lastFireTime = Date.distantPast

    private static let engineRestartNote = Notification.Name("NavikHapticsRestart")

    init() {
        NotificationCenter.default.addObserver(
            forName: Self.engineRestartNote, object: nil, queue: .main
        ) { [weak self] _ in self?.setupEngine() }
        setupEngine()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Self.engineRestartNote, object: nil)
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.resetHandler   = { NotificationCenter.default.post(name: Self.engineRestartNote, object: nil) }
        engine?.stoppedHandler = { _ in NotificationCenter.default.post(name: Self.engineRestartNote, object: nil) }
    }

    // MARK: - Proximity pulse (called every AR frame)
    func pulse(distance: Float) {
        guard isEnabled else { return }
        let (interval, intensity) = params(for: distance)
        guard Date().timeIntervalSince(lastFireTime) >= interval else { return }
        fire(intensity: intensity, sharpness: 0.5)
        lastFireTime = Date()
    }

    private func params(for d: Float) -> (TimeInterval, Float) {
        switch d {
        case 0..<NavConstants.veryCloseThreshold:  return (0.15, 1.0)
        case NavConstants.veryCloseThreshold..<NavConstants.closeThreshold: return (0.4, 0.7)
        case NavConstants.closeThreshold..<NavConstants.mediumThreshold:    return (0.9, 0.45)
        default: return (2.0, 0.25)
        }
    }

    func playSuccess() {
        guard isEnabled else { return }
        let impacts: [(Float, Float, Double)] = [(0.6,0.4,0),(0.9,0.6,0.1),(1.0,0.8,0.22)]
        firePattern(impacts)
    }

    func playWarning() {
        guard isEnabled else { return }
        fire(intensity: 0.5, sharpness: 0.8)
    }

    private func fire(intensity: Float, sharpness: Float) {
        guard let engine else { return }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }

    private func firePattern(_ impacts: [(Float, Float, Double)]) {
        guard let engine else { return }
        let events = impacts.map { (i, s, t) in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: s)
            ], relativeTime: t)
        }
        if let pattern = try? CHHapticPattern(events: events, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}
