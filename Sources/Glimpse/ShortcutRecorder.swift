import SwiftUI
import AppKit
import Carbon

@MainActor
final class ShortcutRecorderController: ObservableObject {
    @Published var isRecording = false
    @Published var capturedShortcut: KeyboardShortcut?

    private var eventMonitor: Any?

    func startRecording() {
        guard !isRecording else { return }
        capturedShortcut = nil
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handle(event: event)
        }
    }

    func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        isRecording = false
    }

    private func handle(event: NSEvent) -> NSEvent? {
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return nil
        }

        if let shortcut = KeyboardShortcut(event: event) {
            capturedShortcut = shortcut
            stopRecording()
            return nil
        } else {
            NSSound.beep()
            return nil
        }
    }
}

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyboardShortcut
    @StateObject private var controller = ShortcutRecorderController()

    var body: some View {
        Button(action: toggleRecording) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    GlimpsePalette.accent.opacity(controller.isRecording ? 0.8 : 0.4),
                                    GlimpsePalette.accent.opacity(controller.isRecording ? 0.6 : 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 32)
                    Image(systemName: controller.isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.isRecording ? "Press new shortcut…" : shortcut.displayString)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(controller.isRecording ? "Press Esc to cancel" : "Current toggle shortcut")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .offset(x: -2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(controller.isRecording ? 0.24 : 0.14),
                                Color.white.opacity(controller.isRecording ? 0.14 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(controller.isRecording ? 0.4 : 0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(controller.isRecording ? 0.35 : 0.18), radius: controller.isRecording ? 18 : 12, y: 8)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onReceive(controller.$capturedShortcut.compactMap { $0 }) { newShortcut in
            shortcut = newShortcut
        }
        .onChange(of: shortcut) { _ in
            controller.stopRecording()
        }
        .onDisappear {
            controller.stopRecording()
        }
    }

    private func toggleRecording() {
        if controller.isRecording {
            controller.stopRecording()
        } else {
            controller.startRecording()
        }
    }
}
