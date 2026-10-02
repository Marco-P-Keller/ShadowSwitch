import SwiftUI

struct ChallengeCode {
    let seed: UInt64
    let score: Int
    var text: String { "SS-\(String(seed, radix: 36).uppercased())-\(String(score, radix: 36).uppercased())" }
    init(seed: UInt64, score: Int) { self.seed = seed; self.score = score }
    init?(_ raw: String) {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().split(separator: "-").map(String.init)
        guard parts.count == 3, parts[0] == "SS", let s = UInt64(parts[1], radix: 36), let sc = Int(parts[2], radix: 36), s > 0 else { return nil }
        self.seed = s; self.score = sc
    }
}

enum RunMode: Equatable {
    case standard, daily
    case challenge(UInt64, Int)
}

struct RunResult {
    var score = 0, meters = 0, coins = 0, shards = 0, xp = 0
    var newBest = false
    var cause = ""
    var bestChain = 0, closeCalls = 0, events = 0
    var dailyCompleted = false
    var challengeBeaten = false
    var challengeTarget: Int?
    var mode: RunMode = .standard
    var seed: UInt64 = 0
    var canRevive = false
    var tierBefore = 0, tierAfter = 0
    var shareCode: String { ChallengeCode(seed: seed, score: score).text }
}

@MainActor
final class GameSession: ObservableObject {
    enum Screen { case menu, playing, paused, dead }

    @Published var screen: Screen = .menu
    @Published var result = RunResult()
    @Published var cardImage: UIImage?
    @Published var askReview = false
    @Published var pendingChallenge: ChallengeCode?
    @Published var invalidCode = false

    let engine = GameEngine()
    let progress: PlayerData
    private(set) var mode: RunMode = .standard
    private var committed: (shards: Int, xp: Int, meters: Int, bonusDaily: Bool)?
    private var runSeed: UInt64 = 0
    var cardRenderer: ((RunResult) -> UIImage?)?

    init(progress: PlayerData) {
        self.progress = progress
        engine.onSfx = { Sfx.play($0) }
        engine.onDeath = { [weak self] in DispatchQueue.main.async { self?.handleDeath() } }
        startAttract()
    }

    // MARK: Modes

    func startAttract() {
        var c = RunConfig()
        c.autopilot = true
        c.invincible = true
        engine.start(c)
        screen = .menu
    }

    func startRun(_ m: RunMode, forceEvent: GameEvent? = nil) {
        mode = m
        var c = RunConfig()
        switch m {
        case .standard: c.seed = UInt64.random(in: 1...999_999)
        case .daily: c.seed = progress.dailySeed; c.modifier = progress.dailyModifier
        case .challenge(let seed, _): c.seed = seed
        }
        c.forceEvent = forceEvent
        runSeed = c.seed
        committed = nil
        cardImage = nil
        engine.start(c)
        screen = .playing
        Sfx.play(.tap)
    }

    func retry() { startRun(mode == .daily && progress.dailyDone ? .standard : mode) }
    func home() { startAttract() }

    func pause() { guard screen == .playing else { return }; screen = .paused }
    func resume() { guard screen == .paused else { return }; engine.resumeClock(); screen = .playing }

    func tap() {
        if screen == .playing {
            if engine.switchWorld(), !progress.d.tutorialDone, engine.switches >= 3 { progress.d.tutorialDone = true }
        }
    }

    // MARK: Death

    func canReviveNow() -> Bool {
        !engine.revived && (progress.d.revives > 0 || progress.d.shards >= Self.reviveCost)
    }
    static let reviveCost = 150

    func revive() {
        guard canReviveNow() else { return }
        if progress.d.revives > 0 { progress.d.revives -= 1 } else { progress.d.shards -= Self.reviveCost }
        engine.revive()
        screen = .playing
        Sfx.play(.reward)
    }

    private func handleDeath() {
        let e = engine
        var r = RunResult()
        r.mode = mode
        r.seed = runSeed
        r.score = e.score; r.meters = e.meters; r.coins = e.coinsCollected
        r.bestChain = e.bestChain; r.closeCalls = e.closeCalls; r.events = e.eventsSurvived
        r.cause = e.deathCause
        r.tierBefore = progress.passTier

        let totalShards = e.coinsCollected + e.meters / 25
        var totalXP = e.score / 4 + 8
        let prev = committed
        let isContinuation = prev != nil

        // daily
        if mode == .daily {
            if progress.d.dailyBestDay != progress.today { progress.d.dailyBestDay = progress.today; progress.d.dailyBest = 0 }
            progress.d.dailyBest = max(progress.d.dailyBest, e.score)
            if !progress.dailyDone && e.score >= progress.dailyGoal {
                progress.d.dailyDoneDay = progress.today
                progress.d.shards += 150
                totalXP += 150
                r.dailyCompleted = true
            }
        }
        // friend challenge
        if case .challenge(_, let target) = mode {
            r.challengeTarget = target
            if e.score > target {
                r.challengeBeaten = true
                if !progress.d.rivalUnlocked { progress.d.rivalUnlocked = true; progress.unlock(skin: "rival") }
            }
        }

        let dShards = totalShards - (prev?.shards ?? 0)
        let dXP = totalXP - (prev?.xp ?? 0)
        progress.d.shards += max(0, dShards)
        progress.d.xp += max(0, dXP)
        progress.d.totalMeters += e.meters - (prev?.meters ?? 0)
        if !isContinuation { progress.d.totalRuns += 1 }
        if e.score > progress.d.best { progress.d.best = e.score; r.newBest = progress.d.totalRuns > 1 || e.score > 0 }
        progress.d.lastBestChain = max(progress.d.lastBestChain, e.bestChain)
        committed = (totalShards, totalXP, e.meters, false)

        r.shards = totalShards; r.xp = totalXP
        r.canRevive = canReviveNow()
        r.tierAfter = progress.passTier
        result = r
        cardImage = cardRenderer?(r)
        screen = .dead
        if r.newBest { Sfx.play(.best) }

        if !progress.d.reviewAsked && progress.d.totalRuns >= 5 && r.newBest {
            progress.d.reviewAsked = true
            askReview = true
        }
    }

    // MARK: Deep links & codes

    func handle(url: URL) {
        guard url.scheme == "shadowswitch" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let code = comps?.queryItems?.first(where: { $0.name == "code" })?.value, let c = ChallengeCode(code) {
            pendingChallenge = c
        }
    }

    func submit(code: String) -> Bool {
        guard let c = ChallengeCode(code) else { invalidCode = true; return false }
        pendingChallenge = c
        return true
    }

    func shareText() -> String {
        let r = result
        var s = "💀 \"\(r.cause)\" — \(r.score) in Shadow Switch.\nBeat my run: \(r.shareCode)"
        s += "\nhttps://marco-p-keller.github.io/ShadowSwitch/"
        return s
    }
}
