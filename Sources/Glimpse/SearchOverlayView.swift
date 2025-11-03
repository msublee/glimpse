import SwiftUI
import WebKit

struct SearchOverlayView: View {
    @ObservedObject var viewModel: SearchViewModel
    let onDismiss: () -> Void

    @EnvironmentObject private var history: SearchHistoryStore
    @FocusState private var searchFieldFocused: Bool
    @State private var showHistory: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Traffic lights space
            Color.clear
                .frame(height: 28)
                .contentShape(Rectangle())
                .onTapGesture {}

            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                Divider()
                    .background(GlimpsePalette.outline)

                contentRow
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 32,
                        x: 0,
                        y: 16
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
        .padding(1)
        .frame(minWidth: 720, idealWidth: 2000, maxWidth: .infinity, minHeight: 480, idealHeight: 1300, maxHeight: .infinity)
        .onExitCommand { onDismiss() }
        .onAppear {
            searchFieldFocused = true
            viewModel.checkLoginStatus()
        }
        .onChange(of: viewModel.focusTick) { _ in
            searchFieldFocused = true
            viewModel.checkLoginStatus()
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            historyToggle

            // Back button
            HoverButton(isEnabled: viewModel.canGoBack) {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .foregroundStyle(
                        viewModel.canGoBack
                            ? GlimpsePalette.secondaryText
                            : GlimpsePalette.tertiaryText
                    )
            }
            .keyboardShortcut("[", modifiers: .command)
            .accessibilityLabel("Go back")

            // Forward button
            HoverButton(isEnabled: viewModel.canGoForward) {
                viewModel.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .foregroundStyle(
                        viewModel.canGoForward
                            ? GlimpsePalette.secondaryText
                            : GlimpsePalette.tertiaryText
                    )
            }
            .keyboardShortcut("]", modifiers: .command)
            .accessibilityLabel("Go forward")

            searchFieldInput

            HoverButton(isEnabled: true) {
                viewModel.navigateToHome()
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .foregroundStyle(GlimpsePalette.secondaryText)
            }
            .keyboardShortcut("h", modifiers: .command)
            .accessibilityLabel("Go to home")

            HoverButton(isEnabled: true) {
                viewModel.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .foregroundStyle(GlimpsePalette.secondaryText)
            }
            .keyboardShortcut("r", modifiers: .command)
            .accessibilityLabel("Reload page")

            // Hidden button for Cmd+/ shortcut (toggle focus)
            Button {
                if searchFieldFocused {
                    // Already focused on Glimpse search field, move to WebView Google search
                    searchFieldFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        viewModel.focusWebViewSearchField()
                    }
                } else {
                    // Focus on Glimpse search field
                    searchFieldFocused = true
                }
            } label: {
                EmptyView()
            }
            .keyboardShortcut("/", modifiers: .command)
            .frame(width: 0, height: 0)
            .hidden()

            Spacer(minLength: 16)

            if viewModel.isSignedIn {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GlimpsePalette.success)
                    Text("Signed in")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GlimpsePalette.secondaryText)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(GlimpsePalette.success.opacity(0.08))
                )
                .background(DragBlocker())
            } else {
                Button {
                    viewModel.navigateToGoogleSignIn()
                } label: {
                    Label("Sign in", systemImage: "person.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .foregroundStyle(GlimpsePalette.brandPrimary)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(GlimpsePalette.brandPrimary.opacity(0.3), lineWidth: 1)
                )
                .background(DragBlocker())
            }

            Label("Google", systemImage: "globe")
                .font(.system(size: 12, weight: .semibold))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundStyle(GlimpsePalette.secondaryText)
                .background(DragBlocker())
        }
    }

    private var searchFieldInput: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    searchFieldFocused
                        ? GlimpsePalette.brandPrimary
                        : GlimpsePalette.secondaryText
                )
                .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)

            TextField("Search Google", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .focused($searchFieldFocused)
                .onSubmit {
                    viewModel.performSearch()
                }

            if !viewModel.query.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.reset()
                        viewModel.requestFocus()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GlimpsePalette.tertiaryText)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                viewModel.performSearch()
            } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        viewModel.query.isEmpty
                            ? GlimpsePalette.tertiaryText
                            : GlimpsePalette.brandPrimary
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .animation(.easeInOut(duration: 0.2), value: viewModel.query.isEmpty)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            searchFieldFocused
                                ? GlimpsePalette.focusRing
                                : GlimpsePalette.outline,
                            lineWidth: searchFieldFocused ? 2 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)
                )
        )
    }

    private var historyToggle: some View {
        HoverButton(isEnabled: true) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                showHistory.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .symbolVariant(showHistory ? .fill : .none)
                .font(.system(size: 16, weight: .semibold))
                .padding(8)
                .foregroundStyle(GlimpsePalette.secondaryText)
        }
        .keyboardShortcut("b", modifiers: .command)
        .accessibilityLabel("Toggle recent searches sidebar")
    }

    private var contentRow: some View {
        HStack(spacing: 0) {
            if showHistory {
                historyColumn
                    .frame(width: 260)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            webViewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var webViewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(GlimpsePalette.outline, lineWidth: 1)
                )

            WebViewContainer(webView: viewModel.webView)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var historyColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlimpsePalette.secondaryText)
                    .textCase(.uppercase)

                Spacer()

                if !history.entries.isEmpty {
                    Button {
                        withAnimation {
                            history.clear()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GlimpsePalette.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            Divider()
                .background(GlimpsePalette.outline)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if history.entries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(GlimpsePalette.tertiaryText)

                            Text("No searches yet")
                                .font(.system(size: 13, weight: .medium))

                            Text("Your recent queries will appear here")
                                .font(.system(size: 11))
                                .foregroundStyle(GlimpsePalette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(history.entries, id: \.self) { entry in
                            historyChip(for: entry)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(GlimpsePalette.outline, lineWidth: 1)
                )
        )
    }

    private func historyChip(for entry: String) -> some View {
        Button {
            viewModel.query = entry
            viewModel.performSearch()
            viewModel.requestFocus()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(GlimpsePalette.tertiaryText)

                Text(entry)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(GlimpsePalette.brandPrimary)
                    .opacity(0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(GlimpsePalette.outline, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .background(DragBlocker())
    }
}

private struct WebViewContainer: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        // Enable gestures - navigation policy will check session in delegate
        webView.allowsBackForwardNavigationGestures = true

        // Prevent WebView from automatically becoming first responder
        // This is handled by NonFocusingWebView's acceptsFirstResponder
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Ensure WebView doesn't steal focus on updates
    }
}

// Prevents window dragging when clicking on this view
private struct DragBlocker: NSViewRepresentable {
    func makeNSView(context: Context) -> DragBlockingView {
        DragBlockingView()
    }

    func updateNSView(_ nsView: DragBlockingView, context: Context) {}
}

private class DragBlockingView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
}

// Chrome-style hover button with circular background
private struct HoverButton<Label: View>: View {
    let isEnabled: Bool
    let action: () -> Void
    let label: () -> Label

    @State private var isHovered: Bool = false

    init(isEnabled: Bool, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.isEnabled = isEnabled
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .background(
                    Circle()
                        .fill(Color.black.opacity(isHovered && isEnabled ? 0.06 : 0))
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = hovering
        }
        .background(DragBlocker())
    }
}

