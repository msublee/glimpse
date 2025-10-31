import Foundation

@MainActor
final class SearchHistoryStore: ObservableObject {
    static let shared = SearchHistoryStore()

    @Published private(set) var entries: [String]

    private let userDefaults: UserDefaults
    private let maxEntries = 15

    private struct Keys {
        static let history = "search.history.entries"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let stored = userDefaults.array(forKey: Keys.history) as? [String] {
            entries = stored
        } else {
            entries = []
        }
    }

    func record(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        var updated = entries
        updated.removeAll { existing in
            existing.compare(normalized, options: .caseInsensitive) == .orderedSame
        }
        updated.insert(normalized, at: 0)

        if updated.count > maxEntries {
            updated = Array(updated.prefix(maxEntries))
        }

        entries = updated
        userDefaults.set(updated, forKey: Keys.history)
    }

    func clear() {
        entries = []
        userDefaults.removeObject(forKey: Keys.history)
    }
}
