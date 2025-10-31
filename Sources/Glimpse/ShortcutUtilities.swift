import AppKit

enum ShortcutUtilities {
    static func openKeyboardInputSources() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?InputSources") else { return }
        NSWorkspace.shared.open(url)
    }

    static func disableMacInputSourceShortcut() {
        let script = "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{enabled=false; value={ parameters=(32,49,1048576); type=standard; }; }'"
        runShell(script: script)
    }

    private static func runShell(script: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-lc", script]
        do {
            try task.run()
        } catch {
            NSLog("ShortcutUtilities failed to run script: \(error.localizedDescription)")
        }
    }
}
