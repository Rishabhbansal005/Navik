import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [OBPage] = [
        OBPage(icon: "location.fill",        color: AppTheme.primary,
               title: "Welcome to Navik",
               body: "The smartest way to remember where you left things. Designed to assist those facing memory challenges with the power of AR."),
        OBPage(icon: "square.grid.2x2.fill", color: AppTheme.accent,
               title: "Organise by Room",
               body: "Create rooms that match your home. Keep everything neatly organised."),
        OBPage(icon: "arkit",                color: AppTheme.primary,
               title: "Save with AR",
               body: "Point your camera, tap Save. Navik pinpoints the exact real-world location."),
        OBPage(icon: "location.north.fill",  color: AppTheme.success,
               title: "Navigate Back",
               body: "A live AR compass and proximity bar guide you straight to your item every time.")
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            AppTheme.background.ignoresSafeArea()
            LinearGradient(
                colors: [pages[page].color.opacity(0.18), Color.clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: page)

            VStack(spacing: 0) {
                // Page content with transition animation
                OBPageView(page: pages[page])
                    .id(page) 
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(duration: 0.45), value: page)

                bottomControls
            }

            // Native iOS back button — top left, only from page 2 onward
            if page > 0 {
                Button {
                    withAnimation(.spring(duration: 0.4)) { page -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 20)
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: AppTheme.lg) {
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? pages[page].color : Color.secondary.opacity(0.3))
                        .frame(width: i == page ? 28 : 8, height: 8)
                        .animation(.spring(duration: 0.35), value: page)
                }
            }

            // Next / Get Started
            Button {
                if page < pages.count - 1 {
                    withAnimation(.spring(duration: 0.4)) { page += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .font(.navHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        pages[page].color,
                        in: RoundedRectangle(cornerRadius: AppTheme.radius)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.xl)
            .animation(.easeInOut(duration: 0.2), value: page)
        }
        .padding(.bottom, AppTheme.xxl)
        .padding(.top, AppTheme.sm)
    }
}

// MARK: - Page Model
private struct OBPage {
    let icon: String
    let color: Color
    let title: String
    let body: String
}

// MARK: - Single Page View
private struct OBPageView: View {
    let page: OBPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: AppTheme.lg) {
            Spacer()
            Spacer()

            // Icon with layered circles
            ZStack {
                ForEach([1.6, 1.3, 1.0], id: \.self) { scale in
                    Circle()
                        .fill(page.color.opacity(0.07 * scale))
                        .frame(width: 170, height: 170)
                        .scaleEffect(scale)
                }
                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(page.color)
                    .symbolEffect(.breathe)
            }
            .scaleEffect(appeared ? 1 : 0.75)
            .opacity(appeared ? 1 : 0)
            
            Spacer()

            // Text
            VStack(spacing: AppTheme.sm) {
                Text(page.title)
                    .font(.navLargeTitle)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.navBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppTheme.xl)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            Spacer()
            Spacer()
            
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview { OnboardingView() }
