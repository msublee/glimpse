import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var preferences: SearchPreferences
    @EnvironmentObject private var history: SearchHistoryStore

    var body: some View {
        ZStack {
            OverlayBackgroundView()

            ScrollView {
                GlassContainer(cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Glimpse Preferences")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .padding(.top, 20)

                        SettingsSection(title: "Search Engine") {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundStyle(GlimpsePalette.brandPrimary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Google")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Fast and comprehensive search results")
                                        .font(.system(size: 13))
                                        .foregroundStyle(GlimpsePalette.secondaryText)
                                }
                            }
                        }

                        SettingsSection(title: "Keyboard Shortcuts") {
                            VStack(alignment: .leading, spacing: 12) {
                                ShortcutRow(icon: "command", label: "Show/Hide Glimpse", shortcut: preferences.hotKey.displayString)
                                Divider().background(GlimpsePalette.outline)
                                ShortcutRow(icon: "sidebar.left", label: "Toggle Recent Searches", shortcut: "⌘B")
                                ShortcutRow(icon: "house", label: "Go to Home", shortcut: "⌘H")
                                ShortcutRow(icon: "arrow.clockwise", label: "Reload Page", shortcut: "⌘R")
                                ShortcutRow(icon: "magnifyingglass", label: "Focus Search", shortcut: "⌘/")
                                ShortcutRow(icon: "escape", label: "Close Panel", shortcut: "Esc")
                            }
                        }

                        SettingsSection(title: "Global Hotkey") {
                            VStack(alignment: .leading, spacing: 14) {
                                ShortcutRecorder(shortcut: $preferences.hotKey)

                                Text("Click to record a new shortcut. Must include at least one modifier key.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GlimpsePalette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)

                                if preferences.hotKey.matchesMacInputSourceToggle {
                                    WarningCard(
                                        title: "Ctrl+Space conflicts with macOS input source toggle",
                                        message: "한/영 전환 단축키와 겹치므로 비활성화하거나 다른 조합으로 바꾸세요.",
                                        primaryAction: .init(title: "Open Keyboard Settings", handler: ShortcutUtilities.openKeyboardInputSources),
                                        secondaryAction: .init(title: "Disable Automatically", handler: ShortcutUtilities.disableMacInputSourceShortcut)
                                    )
                                }
                            }
                        }

                        SettingsSection(title: "Privacy") {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 20))
                                        .foregroundStyle(GlimpsePalette.success)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Search History")
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("Stored locally on your Mac • \(history.entries.count) entries")
                                            .font(.system(size: 13))
                                            .foregroundStyle(GlimpsePalette.secondaryText)
                                    }

                                    Spacer()

                                    Button(role: .destructive) {
                                        history.clear()
                                    } label: {
                                        Label("Clear", systemImage: "trash")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(nsColor: .textBackgroundColor).opacity(history.entries.isEmpty ? 0.4 : 0.8))
                                    )
                                    .foregroundStyle(history.entries.isEmpty ? GlimpsePalette.tertiaryText : GlimpsePalette.error.opacity(0.8))
                                    .disabled(history.entries.isEmpty)
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .padding(32)
            }
        }
        .frame(minWidth: 480, minHeight: 520)
    }
}

private struct ShortcutRow: View {
    let icon: String
    let label: String
    let shortcut: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(GlimpsePalette.secondaryText)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.primary)

            Spacer()

            Text(shortcut)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(GlimpsePalette.secondaryText)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(GlimpsePalette.outline, lineWidth: 0.5)
                )
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GlimpsePalette.secondaryText)
                .tracking(1.0)

            VStack(alignment: .leading, spacing: 14, content: content)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor).opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(GlimpsePalette.outline, lineWidth: 1)
                        )
                )
        }
    }
}

private struct WarningCard: View {
    let title: String
    let message: String
    struct Action {
        let title: String
        let handler: () -> Void
    }
    let primaryAction: Action
    let secondaryAction: Action?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GlimpsePalette.warning)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(GlimpsePalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(primaryAction.title) {
                    primaryAction.handler()
                }
                .buttonStyle(WarningActionButtonStyle())

                if let secondaryAction {
                    Button(secondaryAction.title) {
                        secondaryAction.handler()
                    }
                    .buttonStyle(WarningActionButtonStyle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(GlimpsePalette.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct WarningActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GlimpsePalette.warning.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GlimpsePalette.warning.opacity(0.3), lineWidth: 1)
            )
            .foregroundStyle(GlimpsePalette.warning)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
