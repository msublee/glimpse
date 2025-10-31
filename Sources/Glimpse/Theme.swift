import SwiftUI

enum GlimpsePalette {
    // Brand Colors - Claude Orange (Exact match)
    static let brandPrimary = Color(red: 0.85, green: 0.47, blue: 0.34)  // Claude Terracotta #D97857
    static let brandSecondary = Color(red: 0.75, green: 0.37, blue: 0.24)  // Claude Dark

    // Interactive States
    static let accent = brandPrimary
    static let accentHover = brandPrimary.opacity(0.85)
    static let accentPressed = brandPrimary.opacity(0.7)

    // Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // Surfaces
    static let backdrop = Color(nsColor: .windowBackgroundColor).opacity(0.96)
    static let surface = Color(nsColor: .controlBackgroundColor).opacity(0.98)
    static let surfaceElevated = Color(nsColor: .controlBackgroundColor)

    // Borders
    static let outline = Color.black.opacity(0.08)
    static let subtleOutline = Color.white.opacity(0.35)
    static let focusRing = brandPrimary

    // Text Hierarchy
    static let primaryText = Color.primary
    static let secondaryText = Color.primary.opacity(0.65)
    static let tertiaryText = Color.primary.opacity(0.45)
    static let placeholderText = Color.primary.opacity(0.35)
}

struct OverlayBackgroundView: View {
    var body: some View {
        ZStack {
            GlimpsePalette.backdrop
            LinearGradient(
                colors: [Color.accentColor.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            RadialGradient(
                colors: [Color.accentColor.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 520
            )
        }
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        )
        .ignoresSafeArea()
    }
}

struct GlassContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(GlimpsePalette.outline, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.16), radius: 28, y: 24)
    }
}

struct FrostCard<Content: View>: View {
    private let padding: EdgeInsets
    let content: () -> Content

    init(padding: CGFloat = 18, @ViewBuilder content: @escaping () -> Content) {
        self.padding = EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(GlimpsePalette.outline, lineWidth: 1)
                    )
            )
    }
}
