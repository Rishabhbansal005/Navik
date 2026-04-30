import SwiftUI

// MARK: - Design System
enum AppTheme {
    // Brand colours
    static let primary   = Color(red: 0.07, green: 0.36, blue: 0.96)
    static let accent    = Color(red: 0.00, green: 0.80, blue: 0.72)
    static let success   = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let warning   = Color(red: 1.00, green: 0.62, blue: 0.04)
    static let danger    = Color(red: 1.00, green: 0.27, blue: 0.23)

    // Backgrounds
    static let background         = Color(.systemGroupedBackground)
    static let surface            = Color(.secondarySystemGroupedBackground)
    static let surfaceSecondary   = Color(.tertiarySystemGroupedBackground)

    // Spacing
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    // Radii
    static let radiusSm: CGFloat = 12
    static let radius:   CGFloat = 18
    static let radiusLg: CGFloat = 24
    static let radiusXl: CGFloat = 32

    // Shadow
    static let shadowColor  = Color.black.opacity(0.06)
    static let shadowRadius: CGFloat = 16
    static let shadowY:      CGFloat = 4
}

// MARK: - Typography
extension Font {
    static let navLargeTitle = Font.system(.largeTitle,  design: .rounded).weight(.bold)
    static let navTitle      = Font.system(.title,       design: .rounded).weight(.semibold)
    static let navTitle2     = Font.system(.title2,      design: .rounded).weight(.semibold)
    static let navTitle3     = Font.system(.title3,      design: .rounded).weight(.semibold)
    static let navHeadline   = Font.system(.headline,    design: .rounded)
    static let navBody       = Font.system(.body,        design: .rounded)
    static let navCallout    = Font.system(.callout,     design: .rounded)
    static let navSubhead    = Font.system(.subheadline, design: .rounded)
    static let navCaption    = Font.system(.caption,     design: .rounded)
    static let navCaption2   = Font.system(.caption2,    design: .rounded)
}

// MARK: - View Modifiers
struct NavCard: ViewModifier {
    var padding: CGFloat = AppTheme.md
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius))
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: 0, y: AppTheme.shadowY)
    }
}

struct NavCircleButton: ViewModifier {
    let color: Color
    let size: CGFloat
    func body(content: Content) -> some View {
        content
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(color == AppTheme.primary ? .white : color)
            .frame(width: size, height: size)
            .background(
                color == AppTheme.primary ? color : color.opacity(0.12),
                in: Circle()
            )
    }
}

extension View {
    func navCard(padding: CGFloat = AppTheme.md) -> some View {
        modifier(NavCard(padding: padding))
    }
    func navCircleButton(color: Color = AppTheme.primary, size: CGFloat = 36) -> some View {
        modifier(NavCircleButton(color: color, size: size))
    }
}

// MARK: - Tracking Quality
enum TrackingQuality: Int, CaseIterable {
    case unavailable = 0, poor = 1, fair = 2, good = 3, excellent = 4

    var label: String {
        switch self {
        case .unavailable: return "Unavailable"
        case .poor:        return "Poor"
        case .fair:        return "Fair"
        case .good:        return "Good"
        case .excellent:   return "Excellent"
        }
    }
    var color: Color {
        switch self {
        case .unavailable: return AppTheme.danger
        case .poor:        return AppTheme.danger
        case .fair:        return AppTheme.warning
        case .good:        return AppTheme.success
        case .excellent:   return AppTheme.success
        }
    }
    var icon: String {
        switch self {
        case .unavailable: return "xmark.circle.fill"
        case .poor:        return "exclamationmark.circle.fill"
        case .fair:        return "minus.circle.fill"
        case .good:        return "checkmark.circle.fill"
        case .excellent:   return "checkmark.circle.fill"
        }
    }
    var canSave: Bool { self >= .good }
}

extension TrackingQuality: Comparable {
    static func < (lhs: TrackingQuality, rhs: TrackingQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
