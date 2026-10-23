import Foundation

/// Mock games for the preview, and pretend Play and Install. Artwork is real,
/// from Steam's CDN; states, playtimes and sizes are made up.
@MainActor final class CouchPreviewStore: ObservableObject {
    @Published private(set) var games: [CouchGame] = CouchPreviewStore.mockGames
    @Published private(set) var banner: String?
    private var bannerTask: Task<Void, Never>?

    var shelves: [CouchShelf] { CouchShelf.make(from: games) }

    func play(_ game: CouchGame) {
        show("Starting \(game.title)…")
        update(game.id) { $0.lastPlayed = Date() }
    }

    /// A pretend download that fills in a few seconds.
    func install(_ game: CouchGame) {
        update(game.id) { $0.state = .downloading(0) }
        Task {
            for step in 1...25 {
                try? await Task.sleep(for: .milliseconds(160))
                update(game.id) { $0.state = step == 25 ? .installed : .downloading(Double(step) / 25) }
            }
        }
    }

    func properties(_ game: CouchGame) {
        show("Properties opens Madeira's settings for \(game.title)")
    }

    func guide(_ item: CouchGuideItem) {
        switch item {
        case .home: break
        case .library: show("Switches to Madeira's touch library")
        case .settings: show("Opens Madeira's Settings")
        case .jit: show("Opens JIT setup")
        case .exit: show("Turns Couch mode off at next start")
        }
    }

    private func update(_ id: String, _ change: (inout CouchGame) -> Void) {
        guard let index = games.firstIndex(where: { $0.id == id }) else { return }
        change(&games[index])
    }

    private func show(_ text: String) {
        banner = text
        bannerTask?.cancel()
        bannerTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled { banner = nil }
        }
    }

    private static let gb: Int64 = 1_000_000_000

    private static func daysAgo(_ days: Double) -> Date { Date().addingTimeInterval(-days * 86_400) }

    static let mockGames: [CouchGame] = [
        .steam(367520, "Hollow Knight", state: .installed, lastPlayed: daysAgo(0.2), minutesPlayed: 3_120, sizeBytes: 9 * gb),
        .steam(1030300, "Hollow Knight: Silksong", state: .installed, lastPlayed: daysAgo(1.5), minutesPlayed: 1_480, sizeBytes: 8 * gb),
        .steam(1145350, "Hades II", state: .installed, lastPlayed: daysAgo(3), minutesPlayed: 2_210, sizeBytes: 10 * gb),
        .steam(268910, "Cuphead", state: .installed, lastPlayed: daysAgo(9), minutesPlayed: 640, sizeBytes: 4 * gb),
        .steam(620, "Portal 2", state: .installed, lastPlayed: daysAgo(21), minutesPlayed: 780, sizeBytes: 12 * gb),
        .steam(1809540, "Nine Sols", state: .downloading(0.42), sizeBytes: 11 * gb),
        .steam(504230, "Celeste", state: .installed, lastPlayed: daysAgo(40), minutesPlayed: 95, sizeBytes: 1_200_000_000),
        .steam(413150, "Stardew Valley", state: .installed, minutesPlayed: 0, sizeBytes: 650_000_000),
        .steam(292030, "The Witcher 3: Wild Hunt", state: .notInstalled, minutesPlayed: 4_600, sizeBytes: 48 * gb),
        .steam(1145360, "Hades", state: .notInstalled, minutesPlayed: 1_900, sizeBytes: 15 * gb),
        .steam(570940, "Dark Souls: Remastered", state: .notInstalled, sizeBytes: 8 * gb),
        .steam(105600, "Terraria", state: .notInstalled, minutesPlayed: 300, sizeBytes: 400_000_000),
        .steam(391540, "Undertale", state: .notInstalled, sizeBytes: 200_000_000),
        .steam(632470, "Disco Elysium", state: .notInstalled, sizeBytes: 20 * gb),
        .steam(1229490, "ULTRAKILL", state: .notInstalled, sizeBytes: 2 * gb),
        .steam(1868140, "DAVE THE DIVER", state: .notInstalled, sizeBytes: 10 * gb),
        CouchGame(id: "added-1", source: .added(UUID()), title: "Age of Empires II", state: .installed,
                  lastPlayed: daysAgo(12), minutesPlayed: 260, sizeBytes: 2 * gb),
        CouchGame(id: "added-2", source: .added(UUID()), title: "Half-Life (GOG)", state: .installed,
                  minutesPlayed: 0, sizeBytes: 600_000_000),
    ]
}
