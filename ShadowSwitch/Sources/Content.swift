import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum World: Int, Codable {
    case real, shadow
    var other: World { self == .real ? .shadow : .real }
    var title: String { self == .real ? "REAL" : "SHADOW" }
}

// MARK: - Palettes & themes

struct WorldPalette {
    let skyTop: Color, skyBottom: Color, far: Color, near: Color
    let ground: Color, groundEdge: Color, obstacle: Color, obstacleEdge: Color, accent: Color
    init(_ skyTop: UInt32, _ skyBottom: UInt32, _ far: UInt32, _ near: UInt32,
         _ ground: UInt32, _ groundEdge: UInt32, _ obstacle: UInt32, _ obstacleEdge: UInt32, _ accent: UInt32) {
        self.skyTop = Color(hex: skyTop); self.skyBottom = Color(hex: skyBottom)
        self.far = Color(hex: far); self.near = Color(hex: near)
        self.ground = Color(hex: ground); self.groundEdge = Color(hex: groundEdge)
        self.obstacle = Color(hex: obstacle); self.obstacleEdge = Color(hex: obstacleEdge)
        self.accent = Color(hex: accent)
    }
}

struct Theme: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let price: Int            // shards, 0 = not purchasable with shards
    let unlockHint: String
    let real: WorldPalette
    let shadow: WorldPalette
    func palette(_ w: World) -> WorldPalette { w == .real ? real : shadow }
}

enum Catalog {
    static let themes: [Theme] = [
        Theme(id: "neon-city", name: "Neon City", blurb: "Sunrise outside. Neon nightmare inside.", price: 0, unlockHint: "",
              real: WorldPalette(0x6EC6FF, 0xFFE3C2, 0xB9A7D8, 0x8E7CC3, 0xF4D6A0, 0xD4A55F, 0xE4572E, 0x8F2A12, 0xFF9F1C),
              shadow: WorldPalette(0x0B0720, 0x3A1470, 0x3A1A6B, 0x23104A, 0x120828, 0x00F0FF, 0xFF2BD6, 0xFFB3F5, 0x00F0FF)),
        Theme(id: "candy-dream", name: "Candy Dream", blurb: "Sweet on the surface. Sticky below.", price: 800, unlockHint: "",
              real: WorldPalette(0xFFB3E6, 0xFFF1C9, 0xFF8FCB, 0xF76BB6, 0xFFE0F0, 0xFF5FA8, 0x7B5CFF, 0x3D22B8, 0xFF5FA8),
              shadow: WorldPalette(0x1F0B3A, 0x5B1B7A, 0x6A2A8F, 0x3A1260, 0x2A0D4A, 0xFFEA00, 0x00FFC6, 0xB3FFEE, 0xFFEA00)),
        Theme(id: "cyber-grid", name: "Cyber Grid", blurb: "Retro-future with a glitch problem.", price: 1500, unlockHint: "",
              real: WorldPalette(0x0D1B2A, 0x1B4965, 0x274C77, 0x1B3A5C, 0x0B1F33, 0x5BC0EB, 0xFF9F1C, 0x8A4B00, 0x5BC0EB),
              shadow: WorldPalette(0x000000, 0x14002B, 0x3D0066, 0x240040, 0x07000F, 0x39FF14, 0xFF0054, 0xFF8FB0, 0x39FF14)),
        Theme(id: "haunted", name: "Haunted Night", blurb: "Season 1 exclusive. Every shadow is a ghost.", price: 0, unlockHint: "Shadow Pass · Tier 13",
              real: WorldPalette(0x2B1B3D, 0xFF8A3D, 0x5A2E5C, 0x3C1F45, 0x2A1626, 0xFF7A00, 0xFF7A00, 0x7A3500, 0xFF7A00),
              shadow: WorldPalette(0x050D05, 0x103010, 0x14401A, 0x0C2410, 0x061206, 0x7CFF4F, 0xB6FF3B, 0xE9FFB0, 0x7CFF4F)),
    ]
    static func theme(_ id: String) -> Theme { themes.first { $0.id == id } ?? themes[0] }

    static let skins: [Skin] = [
        Skin(id: "classic", name: "Shade", rarity: .common, price: 0, real: 0x1B1633, shadow: 0xE8FDFF, accessory: .none, trail: .none, unlockHint: ""),
        Skin(id: "ninja-cat", name: "Ninja Cat", rarity: .common, price: 400, real: 0x222233, shadow: 0xFFC857, accessory: .catEars, trail: .sparkle, unlockHint: ""),
        Skin(id: "ghosty", name: "Ghosty", rarity: .rare, price: 700, real: 0x3D3D5C, shadow: 0xFFFFFF, accessory: .halo, trail: .wisp, unlockHint: ""),
        Skin(id: "bunny", name: "Moon Bunny", rarity: .rare, price: 900, real: 0x4A2C5E, shadow: 0xFFB3E6, accessory: .bunny, trail: .sparkle, unlockHint: ""),
        Skin(id: "ember", name: "Ember Imp", rarity: .epic, price: 1300, real: 0x4A0E0E, shadow: 0xFF6B1A, accessory: .horns, trail: .flame, unlockHint: ""),
        Skin(id: "glitch", name: "Glitch", rarity: .epic, price: 1600, real: 0x0A0A0A, shadow: 0x00FFAA, accessory: .antenna, trail: .glitch, unlockHint: ""),
        Skin(id: "bubblegum", name: "Bubblegum", rarity: .epic, price: 2000, real: 0x6B1B5C, shadow: 0xFF7AD9, accessory: .cap, trail: .rainbow, unlockHint: ""),
        Skin(id: "gold-king", name: "Shadow King", rarity: .legendary, price: 4000, real: 0x3B2A00, shadow: 0xFFD700, accessory: .crown, trail: .sparkle, unlockHint: ""),
        Skin(id: "stardust", name: "Stardust", rarity: .rare, price: 0, real: 0x1E2A5A, shadow: 0xBFD7FF, accessory: .halo, trail: .sparkle, unlockHint: "Shadow Pass · Tier 8 (free)"),
        Skin(id: "storm", name: "Storm", rarity: .epic, price: 0, real: 0x0F2A3A, shadow: 0x7DF9FF, accessory: .antenna, trail: .glitch, unlockHint: "Shadow Pass · Tier 6"),
        Skin(id: "void-walker", name: "Void Walker", rarity: .legendary, price: 0, real: 0x000000, shadow: 0xB388FF, accessory: .horns, trail: .void, unlockHint: "Shadow Pass · Tier 20"),
        Skin(id: "neon-fox", name: "Neon Fox", rarity: .epic, price: 0, real: 0x2A0F0F, shadow: 0xFF8A00, accessory: .catEars, trail: .rainbow, unlockHint: "Starter Bundle"),
        Skin(id: "rival", name: "Rival", rarity: .rare, price: 0, real: 0x2B0F2B, shadow: 0xFF4D6D, accessory: .cap, trail: .flame, unlockHint: "Beat a friend's challenge"),
    ]
    static func skin(_ id: String) -> Skin { skins.first { $0.id == id } ?? skins[0] }
}

enum Accessory { case none, catEars, horns, crown, halo, antenna, cap, bunny }
enum TrailStyle { case none, sparkle, flame, rainbow, glitch, wisp, void }

enum Rarity: String {
    case common = "Common", rare = "Rare", epic = "Epic", legendary = "Legendary"
    var color: Color {
        switch self {
        case .common: return Color(hex: 0x9AA4B5)
        case .rare: return Color(hex: 0x4DA3FF)
        case .epic: return Color(hex: 0xB45CFF)
        case .legendary: return Color(hex: 0xFFC233)
        }
    }
}

struct Skin: Identifiable, Hashable {
    let id: String, name: String
    let rarity: Rarity
    let price: Int
    let real: UInt32, shadow: UInt32
    let accessory: Accessory
    let trail: TrailStyle
    let unlockHint: String
}

// MARK: - Shadow Pass

enum Reward: Hashable {
    case shards(Int), revives(Int), skin(String), theme(String)
    var label: String {
        switch self {
        case .shards(let n): return "\(n)"
        case .revives(let n): return "×\(n)"
        case .skin(let id): return Catalog.skin(id).name
        case .theme(let id): return Catalog.theme(id).name
        }
    }
    var icon: String {
        switch self {
        case .shards: return "diamond.fill"
        case .revives: return "heart.fill"
        case .skin: return "person.fill"
        case .theme: return "moon.stars.fill"
        }
    }
}

struct PassTier: Identifiable {
    let tier: Int
    let free: Reward?
    let premium: Reward
    var id: Int { tier }
}

enum Pass {
    static let seasonName = "Neon Nightmares"
    static let xpPerTier = 150
    static let maxTier = 20
    static let tiers: [PassTier] = (1...maxTier).map { t in
        let free: Reward?
        switch t {
        case 4: free = .revives(1)
        case 8: free = .skin("stardust")
        case 12: free = .revives(2)
        case 16: free = .shards(400)
        case 20: free = .shards(800)
        default: free = t.isMultiple(of: 2) ? .shards(50 + t * 5) : nil
        }
        let premium: Reward
        switch t {
        case 3: premium = .revives(2)
        case 6: premium = .skin("storm")
        case 10: premium = .shards(1000)
        case 13: premium = .theme("haunted")
        case 16: premium = .revives(5)
        case 20: premium = .skin("void-walker")
        default: premium = .shards(100 + t * 15)
        }
        return PassTier(tier: t, free: free, premium: premium)
    }
    static func tier(forXP xp: Int) -> Int { min(maxTier, xp / xpPerTier) }
}

// MARK: - Daily modifiers & events

enum DailyModifier: Int, CaseIterable {
    case switchBudget, ghostTown, turbo, mirror, fog, upsideDown, doubleShards
    var title: String {
        switch self {
        case .switchBudget: return "Switch Budget"
        case .ghostTown: return "Ghost Town"
        case .turbo: return "Turbo Shadow"
        case .mirror: return "Mirror World"
        case .fog: return "Thick Fog"
        case .upsideDown: return "Upside Down"
        case .doubleShards: return "Shard Rain"
        }
    }
    var detail: String {
        switch self {
        case .switchBudget: return "Only 3 switches in the bank. They recharge slowly."
        case .ghostTown: return "The other world is invisible. Trust your gut."
        case .turbo: return "Everything runs 30% faster."
        case .mirror: return "The whole world is flipped left to right."
        case .fog: return "You can barely see what's coming."
        case .upsideDown: return "Gravity took the day off."
        case .doubleShards: return "Shards are worth double today."
        }
    }
    var icon: String {
        switch self {
        case .switchBudget: return "bolt.fill"
        case .ghostTown: return "eye.slash.fill"
        case .turbo: return "flame.fill"
        case .mirror: return "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
        case .fog: return "cloud.fog.fill"
        case .upsideDown: return "arrow.up.arrow.down"
        case .doubleShards: return "sparkles"
        }
    }
}

enum GameEvent: CaseIterable {
    case backwards, talking, lava, upsideDown, mirror, disco, fog, surge
    var banner: String {
        switch self {
        case .backwards: return "EVERYONE WALKS BACKWARDS"
        case .talking: return "THE SHADOWS ARE TALKING"
        case .lava: return "THE SHADOW FLOOR IS LAVA"
        case .upsideDown: return "GRAVITY HAS LEFT THE CHAT"
        case .mirror: return "MIRROR, MIRROR"
        case .disco: return "SHADOW DISCO"
        case .fog: return "WHO TURNED OFF THE LIGHTS?"
        case .surge: return "SPEED SURGE"
        }
    }
    var tip: String {
        switch self {
        case .lava: return "Don't stay in the Shadow World too long!"
        case .surge: return "Hold on tight!"
        default: return "Keep switching!"
        }
    }
}

enum Quips {
    static let speech = ["Don't look back!", "Is it Monday?", "I forgot my shadow.", "Nice switch!", "Are we the baddies?",
                         "Lava is just hot soup.", "Wait… I'm the shadow?", "Tap faster!", "My mom says hi.", "Bro. Brooo."]
    static let realDeath = ["Bonked by a very real crate.", "Impaled by suspiciously pointy things.", "Ran into a wall. A literal one.",
                            "Sawed in half. Rude.", "Met a crate. The crate won.", "Forgot the Real World has rules."]
    static let shadowDeath = ["Hugged a grumpy shadow crystal.", "Got spooked by your own shadow.", "Poked by a neon thorn.",
                              "The Shadow World bites back.", "Tripped over a ghost. Embarrassing.", "Crystal clear mistake."]
    static let lavaDeath = ["Cooked in Shadow Lava. Medium rare.", "The floor was lava. It was literally lava.", "Hot tip: Shadow Lava is hot."]
    static func death(world: World, lava: Bool, event: GameEvent?) -> String {
        if lava { return lavaDeath.randomElement()! }
        if let e = event {
            switch e {
            case .backwards: return "Died while everyone walked backwards. Classic."
            case .talking: return "A shadow was mid-sentence. You interrupted. Rude."
            case .upsideDown: return "Died upside down. Gravity is a suggestion."
            case .mirror: return "Mirror image, real death."
            case .disco: return "Died on the dance floor. Iconic."
            case .fog: return "What you couldn't see did hurt you."
            case .surge: return "Too fast, too shadowy."
            case .lava: break
            }
        }
        return (world == .real ? realDeath : shadowDeath).randomElement()!
    }
}
