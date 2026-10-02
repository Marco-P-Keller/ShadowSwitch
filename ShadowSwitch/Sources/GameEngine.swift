import SwiftUI

struct SplitMix: RandomNumberGenerator {
    var s: UInt64
    init(_ seed: UInt64) { s = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        s = s &+ 0x9E3779B97F4A7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> CGFloat { CGFloat(next() % 100_000) / 100_000 }
    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * unit() }
    mutating func int(_ n: Int) -> Int { Int(next() % UInt64(max(n, 1))) }
}

struct Obstacle {
    var x: CGFloat, w: CGFloat
    var world: World
    var kind: Int
    var entered = false, passed = false
    var h: CGFloat { [12, 10, 21, 12][kind % 4] }
}
struct Coin { var x: CGFloat, y: CGFloat, taken = false }
struct Particle {
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat
    var life: CGFloat, maxLife: CGFloat, size: CGFloat
    var color: Color
    var glow = false
}
struct Popup { var text: String; var x: CGFloat; var y: CGFloat; var life: CGFloat; var color: Color }

struct RunConfig {
    var seed: UInt64 = UInt64.random(in: 1...999_999)
    var modifier: DailyModifier? = nil
    var autopilot = false
    var forceEvent: GameEvent? = nil     // used for store screenshots
    var invincible = false
}

final class GameEngine {
    // virtual space: height = 100 units
    static let H: CGFloat = 100
    let groundY: CGFloat = 76
    let playerX: CGFloat = 28
    let playerW: CGFloat = 7
    var viewW: CGFloat = 216

    enum Phase { case idle, running, dead }
    var phase: Phase = .idle
    var cfg = RunConfig()
    private var rng = SplitMix(1)
    private var evRng = SplitMix(2)

    // time & motion
    var clock: CGFloat = 0
    var t: CGFloat = 0
    var scroll: CGFloat = 0
    var speed: CGFloat = 56
    private var lastDate: TimeInterval?
    private var acc: TimeInterval = 0
    private let step: CGFloat = 1.0 / 120.0

    // player
    var world: World = .real
    var prevWorld: World = .real
    var reveal: CGFloat = 1
    var lastSwitchT: CGFloat = -10
    var squash: CGFloat = 0
    var invuln: CGFloat = 0
    var revived = false
    var tokens: CGFloat = 3
    var heat: CGFloat = 0

    // world content
    var obstacles: [Obstacle] = []
    var coins: [Coin] = []
    var particles: [Particle] = []
    var popups: [Popup] = []
    private var spawnX: CGFloat = 0
    private var lastWorld: World = .shadow
    private var trailTimer: CGFloat = 0

    // scoring
    var coinsCollected = 0
    var bonus = 0
    var chain = 0
    var bestChain = 0
    var chainTimer: CGFloat = 0
    var switches = 0
    var closeCalls = 0
    var eventsSurvived = 0
    var meters: Int { Int(scroll / 8) }
    var score: Int { meters + bonus }

    // events
    var event: GameEvent?
    var eventT: CGFloat = 0
    let eventDuration: CGFloat = 9
    private var nextEventAt: CGFloat = 14
    private var eventBag: [GameEvent] = []
    var flip: CGFloat = 0
    var mirrorAmt: CGFloat = 0
    var fogAmt: CGFloat = 0
    var banner: String?
    var bannerLife: CGFloat = 0
    var shake: CGFloat = 0
    var flash: CGFloat = 0
    var deathCause = ""
    var deathObstacleKind = 0
    var hintFirst = true

    // callbacks
    var onDeath: (() -> Void)?
    var onSfx: ((SfxKind) -> Void)?

    // MARK: - Lifecycle

    func start(_ config: RunConfig) {
        cfg = config
        rng = SplitMix(config.seed)
        evRng = SplitMix(config.seed ^ 0xA5A5_5A5A_1234)
        t = 0; scroll = 0; speed = 56
        world = .real; prevWorld = .real; reveal = 1; lastSwitchT = -10; squash = 0
        invuln = 0; revived = false; tokens = 3; heat = 0
        obstacles = []; coins = []; particles = []; popups = []
        spawnX = 110; lastWorld = .shadow
        coinsCollected = 0; bonus = 0; chain = 0; bestChain = 0; chainTimer = 0
        switches = 0; closeCalls = 0; eventsSurvived = 0
        event = nil; eventT = 0; nextEventAt = 14; eventBag = []
        flip = 0; mirrorAmt = 0; fogAmt = 0; banner = nil; bannerLife = 0; shake = 0; flash = 0
        hintFirst = !config.autopilot
        lastDate = nil; acc = 0
        phase = .running
        if let e = config.forceEvent { beginEvent(e) }
        fillAhead()
    }

    func resumeClock() { lastDate = nil }

    func advance(to date: TimeInterval) {
        guard let last = lastDate else { lastDate = date; return }
        let dt = min(date - last, 0.1)
        lastDate = date
        clock += CGFloat(dt)
        acc += dt
        let s = TimeInterval(step)
        while acc >= s {
            acc -= s
            if phase == .running { simulate(step) } else { decorate(step) }
        }
    }

    // MARK: - Input

    @discardableResult
    func switchWorld() -> Bool {
        guard phase == .running else { return false }
        if cfg.modifier == .switchBudget {
            guard tokens >= 1 else { shake = max(shake, 0.4); return false }
            tokens -= 1
        }
        prevWorld = world
        world = world.other
        reveal = 0
        lastSwitchT = t
        squash = 1
        switches += 1
        onSfx?(world == .real ? .switchReal : .switchShadow)
        burst(at: playerX + 3, y: groundY - 6, color: world == .shadow ? Color(hex: 0x00F0FF) : Color(hex: 0xFFB36B), count: 10, speed: 40)
        return true
    }

    func revive() {
        guard phase == .dead else { return }
        revived = true
        phase = .running
        invuln = 2.2
        obstacles.removeAll { $0.x < scroll + 140 && $0.x + $0.w > scroll + playerX - 5 }
        heat = 0
        lastDate = nil
        popups.append(Popup(text: "SECOND CHANCE", x: playerX, y: 40, life: 1.4, color: .white))
    }

    // MARK: - Simulation

    private func baseSpeed(at time: CGFloat) -> CGFloat {
        var s = 56 + min(time, 150) * 0.5
        if cfg.modifier == .turbo { s *= 1.3 }
        return s
    }

    private func simulate(_ dt: CGFloat) {
        t += dt
        var target = baseSpeed(at: t)
        if event == .surge { target *= 1.22 }
        speed += (target - speed) * min(1, dt * 3)
        scroll += speed * dt

        if reveal < 1 { reveal = min(1, reveal + dt / 0.45) }
        squash = max(0, squash - dt * 5)
        invuln = max(0, invuln - dt)
        shake = max(0, shake - dt * 2.5)
        flash = max(0, flash - dt * 3)
        if bannerLife > 0 { bannerLife -= dt; if bannerLife <= 0 { banner = nil } }
        if chain > 0 { chainTimer -= dt; if chainTimer <= 0 { chain = 0 } }
        if cfg.modifier == .switchBudget { tokens = min(3, tokens + dt / 3.5) }

        if cfg.autopilot { runBot() }
        updateEvents(dt)
        fillAhead()
        collide(dt)
        updateTrail(dt)
        decorate(dt)

        obstacles.removeAll { $0.x + $0.w < scroll - 30 }
        coins.removeAll { $0.x < scroll - 30 || $0.taken }
    }

    private func decorate(_ dt: CGFloat) {
        for i in particles.indices {
            particles[i].life -= dt
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt
        }
        particles.removeAll { $0.life <= 0 }
        for i in popups.indices { popups[i].life -= dt; popups[i].y -= 10 * dt }
        popups.removeAll { $0.life <= 0 }
        let tf: CGFloat = (event == .upsideDown || cfg.modifier == .upsideDown) ? 1 : 0
        let tm: CGFloat = (event == .mirror || cfg.modifier == .mirror) ? 1 : 0
        let tg: CGFloat = (event == .fog || cfg.modifier == .fog) ? 1 : 0
        flip += (tf - flip) * min(1, dt * 4)
        mirrorAmt += (tm - mirrorAmt) * min(1, dt * 4)
        fogAmt += (tg - fogAmt) * min(1, dt * 3)
    }

    // MARK: - Events

    private func updateEvents(_ dt: CGFloat) {
        if let e = event {
            eventT += dt
            if e == .lava {
                if world == .shadow { heat += dt } else { heat = max(0, heat - dt * 2) }
                if heat >= 1.8 && invuln <= 0 && !cfg.invincible { die(cause: Quips.death(world: .shadow, lava: true, event: nil)) }
            }
            if eventT >= eventDuration {
                event = nil
                heat = 0
                eventsSurvived += 1
                bonus += 50
                popups.append(Popup(text: "+50 SURVIVED", x: playerX + 10, y: 50, life: 1.2, color: Color(hex: 0xFFD54F)))
                nextEventAt = t + evRng.range(6, 10)
            }
        } else if t >= nextEventAt {
            if eventBag.isEmpty { eventBag = GameEvent.allCases.shuffled(using: &evRng) }
            beginEvent(eventBag.removeLast())
        }
    }

    private func beginEvent(_ e: GameEvent) {
        event = e
        eventT = 0
        banner = e.banner
        bannerLife = 2.6
        flash = 1
        shake = e == .surge ? 0.8 : 0.4
        onSfx?(.event)
    }

    // MARK: - Generation

    private func fillAhead() {
        while spawnX < scroll + viewW + 80 { spawnPattern() }
    }

    private func spawnPattern() {
        let diff = min(1, t / 110)
        let plan = baseSpeed(at: t + 2.5)
        let window = 0.46 - 0.25 * diff

        func gap(to next: World) -> CGFloat {
            if next == lastWorld { return rng.range(16, 38) - 8 * diff }
            return plan * (window + rng.range(0, 0.28)) + 6
        }
        func place(_ w: World, width: CGFloat, preGap: CGFloat) {
            spawnX += preGap
            obstacles.append(Obstacle(x: spawnX, w: width, world: w, kind: rng.int(4)))
            spawnX += width
            lastWorld = w
        }
        func coinsIn(_ start: CGFloat, _ end: CGFloat) {
            guard end - start > 16 else { return }
            let n = Int((end - start - 8) / 7)
            for i in 0..<min(n, 6) {
                let x = start + 6 + CGFloat(i) * 7
                coins.append(Coin(x: x, y: groundY - 8 - sin(CGFloat(i) / CGFloat(max(n - 1, 1)) * .pi) * 7))
            }
        }

        if obstacles.isEmpty && hintFirst {
            hintFirst = false
            place(.real, width: 9, preGap: 20)
            return
        }

        let r = rng.unit()
        if r < 0.32 {
            let w: World = rng.unit() < 0.5 ? lastWorld : lastWorld.other
            let g = gap(to: w)
            let before = spawnX
            place(w, width: rng.range(6, 11), preGap: g)
            coinsIn(before + 2, before + g)
        } else if r < 0.52 {
            let w = lastWorld.other
            let g = gap(to: w)
            let before = spawnX
            place(w, width: rng.range(18, 30) + diff * 6, preGap: g)
            coinsIn(before + 2, before + g)
        } else if r < 0.88 {
            let count = 2 + rng.int(2 + Int(diff * 3))
            var w = lastWorld.other
            for i in 0..<count {
                let g = gap(to: w)
                if i == 0 { let before = spawnX; coinsIn(before + 2, before + g) }
                place(w, width: rng.range(5, 8), preGap: g)
                w = w.other
            }
        } else {
            let g = gap(to: lastWorld) + 20
            let before = spawnX
            coinsIn(before, before + g)
            place(lastWorld, width: rng.range(7, 12), preGap: g)
        }
    }

    // MARK: - Collision

    private func collide(_ dt: CGFloat) {
        let hitL = scroll + playerX + 1.4
        let hitR = scroll + playerX + playerW - 1.2
        for i in obstacles.indices {
            let o = obstacles[i]
            if !o.entered && o.x < hitR {
                obstacles[i].entered = true
                if o.world != world && t - lastSwitchT < 0.16 && t - lastSwitchT >= 0 { closeCall(at: o) }
            }
            if o.x < hitR && o.x + o.w > hitL {
                if o.world == world && invuln <= 0 && !cfg.invincible {
                    deathObstacleKind = o.kind
                    die(cause: Quips.death(world: world, lava: false, event: event))
                    return
                }
            }
            if !o.passed && o.x + o.w < hitL {
                obstacles[i].passed = true
                let gain = 3 * (1 + chain / 3)
                bonus += gain
            }
        }
        for i in coins.indices where !coins[i].taken {
            let c = coins[i]
            if c.x > hitL - 2 && c.x < hitR + 2 {
                coins[i].taken = true
                let v = cfg.modifier == .doubleShards ? 2 : 1
                coinsCollected += v
                onSfx?(.coin)
                burst(at: c.x - scroll, y: c.y, color: Color(hex: 0xFFD54F), count: 5, speed: 22)
            }
        }
    }

    private func closeCall(at o: Obstacle) {
        closeCalls += 1
        chain += 1
        bestChain = max(bestChain, chain)
        chainTimer = 6
        let gain = 15 * chain
        bonus += gain
        popups.append(Popup(text: chain > 1 ? "CLOSE CALL ×\(chain)  +\(gain)" : "CLOSE CALL +\(gain)",
                            x: playerX - 4, y: groundY - 24, life: 1.0, color: Color(hex: 0xFFEB3B)))
        flash = max(flash, 0.35)
        onSfx?(.closeCall)
    }

    private func die(cause: String) {
        guard phase == .running else { return }
        phase = .dead
        deathCause = cause
        shake = 1
        flash = 1
        let c = world == .real ? Color(hex: 0x1B1633) : Color(hex: 0x00F0FF)
        burst(at: playerX + 3, y: groundY - 6, color: c, count: 34, speed: 70)
        burst(at: playerX + 3, y: groundY - 6, color: .white, count: 12, speed: 50)
        onSfx?(.death)
        onDeath?()
    }

    // MARK: - Particles

    func burst(at x: CGFloat, y: CGFloat, color: Color, count: Int, speed: CGFloat) {
        guard particles.count < 400 else { return }
        for _ in 0..<count {
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let v = CGFloat.random(in: speed * 0.3...speed)
            particles.append(Particle(x: x, y: y, vx: cos(a) * v, vy: sin(a) * v - 10,
                                      life: 0.5, maxLife: 0.5, size: CGFloat.random(in: 0.6...1.6), color: color, glow: true))
        }
    }

    private func updateTrail(_ dt: CGFloat) {
        trailTimer -= dt
        guard trailTimer <= 0 else { return }
        trailTimer = 0.025
        let skinTrail = trailStyle
        guard skinTrail != .none else { return }
        let hue = Double((clock * 0.8).truncatingRemainder(dividingBy: 1))
        let color: Color
        switch skinTrail {
        case .sparkle: color = Color(hex: 0xFFE9A8)
        case .flame: color = Bool.random() ? Color(hex: 0xFF6B1A) : Color(hex: 0xFFC107)
        case .rainbow: color = Color(hue: hue, saturation: 0.8, brightness: 1)
        case .glitch: color = Bool.random() ? Color(hex: 0x00FFAA) : Color(hex: 0xFF0066)
        case .wisp: color = Color.white.opacity(0.8)
        case .void: color = Color(hex: 0xB388FF)
        case .none: color = .clear
        }
        particles.append(Particle(x: playerX + 1, y: groundY - 5 + CGFloat.random(in: -3...3),
                                  vx: -speed * 0.5, vy: CGFloat.random(in: -6...6),
                                  life: 0.45, maxLife: 0.45, size: CGFloat.random(in: 0.8...1.8), color: color))
    }

    var trailStyle: TrailStyle = .none

    // MARK: - Bot (menu attract mode)

    private func runBot() {
        let hitL = scroll + playerX + 1.4
        let hitR = scroll + playerX + playerW - 1.2
        let look = speed * 0.2
        // escape the lava when it gets hot, unless a real-world obstacle is about to arrive
        if event == .lava && world == .shadow && heat > 1.0 {
            let blocked = obstacles.contains { $0.world == .real && $0.x + $0.w > hitL && $0.x - hitR < look * 1.5 }
            if !blocked { _ = switchWorld(); return }
        }
        for o in obstacles where o.x + o.w > hitL {
            if o.x < hitR { return }          // currently overlapping, hold
            if o.x - hitR < look {
                if o.world == world { _ = switchWorld() }
                return
            }
            return
        }
    }

    // MARK: - Self test (headless bot run, used to validate fairness of the generator)

    static func selfTest(seeds: Int, seconds: CGFloat) -> String {
        var survived = 0, total: CGFloat = 0, worst: CGFloat = 999
        var lines: [String] = []
        for seed in 1...seeds {
            let e = GameEngine()
            var c = RunConfig(); c.seed = UInt64(seed); c.autopilot = true
            if seed % 7 == 0 { c.modifier = DailyModifier.allCases[(seed / 7) % DailyModifier.allCases.count] }
            if c.modifier == .switchBudget { c.modifier = nil }
            e.start(c)
            var date: TimeInterval = 1000
            e.advance(to: date)
            while e.phase == .running && e.t < seconds {
                date += 1.0 / 60
                e.advance(to: date)
            }
            total += e.t
            if e.phase == .running { survived += 1 } else {
                worst = min(worst, e.t)
                lines.append("seed \(seed) died at t=\(Int(e.t))s speed=\(Int(e.speed)) event=\(String(describing: e.event)) cause=\(e.deathCause)")
            }
        }
        return "survived \(survived)/\(seeds) avg t=\(Int(total / CGFloat(seeds)))s worst=\(Int(worst))s\n" + lines.prefix(15).joined(separator: "\n")
    }
}
