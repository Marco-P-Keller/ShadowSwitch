import SwiftUI
import Combine

struct SaveData: Codable {
    var shards = 150
    var xp = 0
    var best = 0
    var totalRuns = 0
    var totalMeters = 0
    var ownedSkins: [String] = ["classic"]
    var skin = "classic"
    var ownedThemes: [String] = ["neon-city"]
    var theme = "neon-city"
    var passPremium = false
    var claimedFree: [Int] = []
    var claimedPremium: [Int] = []
    var revives = 1
    var starterBought = false
    var installDate = Date()
    var streak = 0
    var lastStreakDay = ""
    var loginClaimedDay = ""
    var dailyDoneDay = ""
    var dailyBestDay = ""
    var dailyBest = 0
    var sound = true
    var music = true
    var haptics = true
    var reduceFX = false
    var tutorialDone = false
    var rivalUnlocked = false
    var reviewAsked = false
    var lastBestChain = 0
}

@MainActor
final class PlayerData: ObservableObject {
    @Published var d: SaveData
    private var bag = Set<AnyCancellable>()
    private static let key = "shadowswitch.save.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let s = try? JSONDecoder().decode(SaveData.self, from: data) {
            d = s
        } else {
            d = SaveData()
        }
        $d.dropFirst().debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { s in
                if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: Self.key) }
            }.store(in: &bag)
        refreshStreak()
    }

    static func dayString(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    var today: String { Self.dayString() }
    var dailySeed: UInt64 { UInt64(today) ?? 1 }
    var dailyModifier: DailyModifier { DailyModifier.allCases[Int(dailySeed % UInt64(DailyModifier.allCases.count))] }
    var dailyGoal: Int { 250 + Int(dailySeed % 5) * 50 }
    var dailyDone: Bool { d.dailyDoneDay == today }
    var dailyBestToday: Int { d.dailyBestDay == today ? d.dailyBest : 0 }

    var passTier: Int { Pass.tier(forXP: d.xp) }
    var skin: Skin { Catalog.skin(d.skin) }
    var theme: Theme { Catalog.theme(d.theme) }

    // MARK: Streak / login reward
    func refreshStreak() {
        if d.lastStreakDay == today { return }
        let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        d.streak = (d.lastStreakDay == yesterday) ? d.streak + 1 : 1
        d.lastStreakDay = today
    }
    var loginRewardAvailable: Bool { d.loginClaimedDay != today }
    var loginReward: Int { 40 + min(d.streak, 7) * 20 }
    func claimLogin() {
        guard loginRewardAvailable else { return }
        d.shards += loginReward
        d.loginClaimedDay = today
    }

    // MARK: Ownership
    func owns(skin id: String) -> Bool { d.ownedSkins.contains(id) }
    func owns(theme id: String) -> Bool { d.ownedThemes.contains(id) }
    func unlock(skin id: String) { if !owns(skin: id) { d.ownedSkins.append(id) } }
    func unlock(theme id: String) { if !owns(theme: id) { d.ownedThemes.append(id) } }

    @discardableResult
    func buy(skin: Skin) -> Bool {
        guard skin.price > 0, !owns(skin: skin.id), d.shards >= skin.price else { return false }
        d.shards -= skin.price; unlock(skin: skin.id); d.skin = skin.id
        return true
    }
    @discardableResult
    func buy(theme: Theme) -> Bool {
        guard theme.price > 0, !owns(theme: theme.id), d.shards >= theme.price else { return false }
        d.shards -= theme.price; unlock(theme: theme.id); d.theme = theme.id
        return true
    }

    // MARK: Pass
    func grant(_ r: Reward) {
        switch r {
        case .shards(let n): d.shards += n
        case .revives(let n): d.revives += n
        case .skin(let id): unlock(skin: id)
        case .theme(let id): unlock(theme: id)
        }
    }
    func canClaim(tier: PassTier, premium: Bool) -> Bool {
        guard passTier >= tier.tier else { return false }
        if premium { return d.passPremium && !d.claimedPremium.contains(tier.tier) }
        return tier.free != nil && !d.claimedFree.contains(tier.tier)
    }
    func claim(tier: PassTier, premium: Bool) {
        guard canClaim(tier: tier, premium: premium) else { return }
        if premium { d.claimedPremium.append(tier.tier); grant(tier.premium) }
        else if let f = tier.free { d.claimedFree.append(tier.tier); grant(f) }
    }
    var unclaimedCount: Int {
        Pass.tiers.filter { canClaim(tier: $0, premium: false) || canClaim(tier: $0, premium: true) }.count
    }

    // MARK: Purchases
    func applyStarter() {
        guard !d.starterBought else { return }
        d.starterBought = true
        d.shards += 1000; d.revives += 3
        unlock(skin: "neon-fox")
    }
}
