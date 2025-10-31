import Foundation

enum SearchEngine: String, CaseIterable, Identifiable {
    case duckDuckGo
    case brave
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .duckDuckGo:
            return "DuckDuckGo"
        case .brave:
            return "Brave Search"
        case .google:
            return "Google"
        }
    }

    var placeholderSubtitle: String {
        switch self {
        case .duckDuckGo:
            return "Privacy-first results with instant answers."
        case .brave:
            return "Independent index with AI summaries."
        case .google:
            return "Comprehensive search across the web."
        }
    }

    func searchURL(for query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let encoded else { return nil }
        let urlString: String

        switch self {
        case .duckDuckGo:
            urlString = "https://duckduckgo.com/?ia=web&q=\(encoded)"
        case .brave:
            urlString = "https://search.brave.com/search?q=\(encoded)"
        case .google:
            urlString = "https://www.google.com/search?q=\(encoded)"
        }

        return URL(string: urlString)
    }
}
