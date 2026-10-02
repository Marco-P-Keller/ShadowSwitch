import SwiftUI

/// Launch-argument driven scenes, used to capture App Store screenshots deterministically.
/// Usage: `xcrun simctl launch <device> com.connexa.shadowswitch -demo play-real`
enum Demo {
    @MainActor
    static func apply(session: GameSession, progress: PlayerData, setPanel: @escaping (ActivePanel?) -> Void) {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-demo"), i + 1 < args.count else { return }
        let scene = args[i + 1]
        progress.d.tutorialDone = true
        progress.d.totalRuns = 6
        progress.d.best = 1284
        progress.d.streak = 5
        progress.d.shards = 2480
        progress.d.xp = 1190
        progress.d.revives = 3
        progress.d.passPremium = false
        progress.d.ownedSkins = ["classic", "ninja-cat", "ember"]
        progress.d.loginClaimedDay = ""

        func run(_ event: GameEvent?, skin: String = "classic", modifier: DailyModifier? = nil) {
            progress.d.skin = skin
            var c = RunConfig()
            c.seed = 4242; c.autopilot = true; c.invincible = true; c.forceEvent = event; c.modifier = modifier
            session.engine.start(c)
            session.engine.onDeath = nil
            session.screen = .playing
        }
        switch scene {
        case "menu": session.startAttract()
        case "play-real", "play": run(nil)
        case "play-lava": run(.lava, skin: "ember")
        case "play-upside": run(.upsideDown, skin: "ninja-cat")
        case "play-talk": run(.talking)
        case "play-back": run(.backwards)
        case "play-disco": run(.disco, skin: "ninja-cat")
        case "play-fog": run(.fog)
        case "play-surge": run(.surge)
        case "daily": session.startAttract(); setPanel(.daily)
        case "pass": session.startAttract(); setPanel(.pass)
        case "skins": session.startAttract(); setPanel(.skins)
        case "worlds": session.startAttract(); setPanel(.worlds)
        case "shop": session.startAttract(); setPanel(.shards)
        case "dead":
            progress.d.skin = "ember"
            var c = RunConfig(); c.seed = 777
            session.startRun(.standard)
            session.engine.start(c)
            session.engine.scroll = 3800
            session.engine.bonus = 215
            session.engine.coinsCollected = 37
        default: break
        }
    }
}
