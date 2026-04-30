import Foundation
import simd

// MARK: - Room Model
struct RoomModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, iconName: String) {
        self.id        = id
        self.name      = name
        self.iconName  = iconName
        self.createdAt = Date()
    }

    static let defaultRooms: [RoomModel] = [
        RoomModel(name: "Bedroom",     iconName: "bed.double.fill"),
        RoomModel(name: "Kitchen",     iconName: "fork.knife"),
        RoomModel(name: "Living Room", iconName: "sofa.fill"),
        RoomModel(name: "Study",       iconName: "books.vertical.fill"),
        RoomModel(name: "Garage",      iconName: "car.fill")
    ]

    static func == (lhs: RoomModel, rhs: RoomModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Item Model
struct ItemModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var roomID: UUID
    var locationDescription: String
    var timestamp: Date
    var iconName: String
    var emoji: String?
    var imageData: Data?
    var saveQuality: Float

    // AR transform stored as flat array for Codable conformance
    private var transformArray: [Float]
    var worldMapData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        roomID: UUID,
        iconName: String,
        emoji: String? = nil,
        imageData: Data? = nil,
        locationDescription: String = "",
        anchorTransform: simd_float4x4 = matrix_identity_float4x4,
        worldMapData: Data? = nil,
        saveQuality: Float = 0
    ) {
        self.id                  = id
        self.name                = name
        self.roomID              = roomID
        self.iconName            = iconName
        self.emoji               = emoji
        self.imageData           = imageData
        self.locationDescription = locationDescription
        self.timestamp           = Date()
        self.worldMapData        = worldMapData
        self.saveQuality         = saveQuality
        self.transformArray      = anchorTransform.flatArray
    }

    var anchorTransform: simd_float4x4 {
        get { transformArray.count == 16 ? simd_float4x4(flatArray: transformArray) : matrix_identity_float4x4 }
        set { transformArray = newValue.flatArray }
    }

    static func == (lhs: ItemModel, rhs: ItemModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - simd helpers
extension simd_float4x4 {
    var flatArray: [Float] {
        let c = columns
        return [c.0.x,c.0.y,c.0.z,c.0.w, c.1.x,c.1.y,c.1.z,c.1.w,
                c.2.x,c.2.y,c.2.z,c.2.w, c.3.x,c.3.y,c.3.z,c.3.w]
    }
    init(flatArray a: [Float]) {
        self = simd_float4x4(
            SIMD4(a[0],a[1],a[2],a[3]),   SIMD4(a[4],a[5],a[6],a[7]),
            SIMD4(a[8],a[9],a[10],a[11]), SIMD4(a[12],a[13],a[14],a[15])
        )
    }
    var position: SIMD3<Float> { SIMD3(columns.3.x, columns.3.y, columns.3.z) }

    func distance(to other: simd_float4x4) -> Float {
        let d = position - other.position
        return sqrt(d.x*d.x + d.y*d.y + d.z*d.z)
    }

    /// Signed angle in radians from camera forward to target (horizontal plane)
    func horizontalBearing(to target: simd_float4x4) -> Float {
        let forward  = SIMD3<Float>(-columns.2.x, 0, -columns.2.z)
        let toTarget = SIMD3<Float>(target.position.x - position.x, 0,
                                    target.position.z - position.z)
        let dot = forward.x * toTarget.x + forward.z * toTarget.z
        let det = forward.x * toTarget.z - forward.z * toTarget.x
        return atan2(det, dot)
    }
}

// MARK: - Navigation constants
enum NavConstants {
    static let reachedThreshold:   Float = 0.25   // metres
    static let veryCloseThreshold: Float = 0.75
    static let closeThreshold:     Float = 2.0
    static let mediumThreshold:    Float = 5.0
    static let bearingSmoothing:   Float = 0.15   // lower = smoother
    static let distanceSmoothing:  Float = 0.12
}
