import SwiftUI

struct RenderContext {
    let e: GameEngine
    let theme: Theme
    let skin: Skin
    let viewW: CGFloat
    let reduceFX: Bool
}

enum Renderer {
    static func hash(_ n: Int) -> CGFloat {
        var x = UInt64(bitPattern: Int64(n)) &* 0x9E3779B97F4A7C15
        x ^= x >> 29; x = x &* 0xBF58476D1CE4E5B9; x ^= x >> 32
        return CGFloat(x % 10_000) / 10_000
    }

    // MARK: Entry

    static func draw(_ context: GraphicsContext, size: CGSize, e: GameEngine, theme: Theme, skin: Skin, reduceFX: Bool) {
        var ctx = context
        let k = size.height / GameEngine.H
        let viewW = size.width / k
        e.viewW = viewW
        e.trailStyle = skin.trail
        let rc = RenderContext(e: e, theme: theme, skin: skin, viewW: viewW, reduceFX: reduceFX)

        ctx.scaleBy(x: k, y: k)
        if e.shake > 0 && !reduceFX {
            ctx.translateBy(x: CGFloat.random(in: -1...1) * e.shake * 2.2, y: CGFloat.random(in: -1...1) * e.shake * 2.2)
        }
        var sx = 1 - 2 * e.mirrorAmt, sy = 1 - 2 * e.flip
        if abs(sx) < 0.03 { sx = 0.03 }
        if abs(sy) < 0.03 { sy = 0.03 }
        ctx.translateBy(x: viewW / 2, y: 50)
        ctx.scaleBy(x: sx, y: sy)
        ctx.translateBy(x: -viewW / 2, y: -50)

        if e.reveal >= 1 {
            drawWorld(ctx, rc, e.world)
        } else {
            drawWorld(ctx, rc, e.prevWorld)
            let ease = 1 - pow(1 - e.reveal, 3)
            let r = ease * 330
            let c = CGPoint(x: e.playerX + 3.5, y: e.groundY - 6)
            let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.drawLayer { l in
                l.clip(to: circle)
                drawWorld(l, rc, e.world)
            }
            let pal = theme.palette(e.world)
            ctx.stroke(circle, with: .color((e.world == .shadow ? pal.accent : Color.white).opacity(0.8 * (1 - e.reveal))), lineWidth: 1.6)
        }

        drawParticles(ctx, rc)
        drawPopups(ctx, rc)

        if e.fogAmt > 0.01 {
            let center = CGPoint(x: e.playerX + 20, y: e.groundY - 10)
            let grad = Gradient(stops: [.init(color: .clear, location: 0), .init(color: .clear, location: 0.22),
                                        .init(color: Color(hex: 0x05030F), location: 0.62)])
            var f = ctx
            f.opacity = Double(e.fogAmt) * 0.96
            f.fill(Path(CGRect(x: -50, y: -50, width: viewW + 100, height: 200)),
                   with: .radialGradient(grad, center: center, startRadius: 0, endRadius: 120))
        }
        if e.event == .surge && !reduceFX { drawSpeedLines(ctx, rc) }
        if e.flash > 0 && !reduceFX {
            var f = ctx
            f.opacity = Double(e.flash) * 0.22
            f.fill(Path(CGRect(x: -50, y: -50, width: viewW + 100, height: 200)), with: .color(.white))
        }
    }

    // MARK: World

    static func drawWorld(_ context: GraphicsContext, _ rc: RenderContext, _ world: World) {
        var ctx = context
        let e = rc.e
        let pal = rc.theme.palette(world)
        let W = rc.viewW
        let gy = e.groundY
        let full = CGRect(x: -60, y: -60, width: W + 120, height: 230)

        // sky
        ctx.fill(Path(full), with: .linearGradient(Gradient(colors: [pal.skyTop, pal.skyBottom]),
                                                    startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: gy)))
        if e.event == .disco {
            let hue = Double((e.clock * 0.35).truncatingRemainder(dividingBy: 1))
            var d = ctx
            d.opacity = 0.28 + 0.12 * Double(sin(e.clock * 9))
            d.fill(Path(full), with: .color(Color(hue: hue, saturation: 0.9, brightness: 1)))
        }

        // celestial
        if world == .real {
            let sun = CGPoint(x: W * 0.78, y: 26)
            ctx.fill(Path(ellipseIn: CGRect(x: sun.x - 17, y: sun.y - 17, width: 34, height: 34)), with: .color(Color(hex: 0xFFF2B3, opacity: 0.35)))
            ctx.fill(Path(ellipseIn: CGRect(x: sun.x - 10, y: sun.y - 10, width: 20, height: 20)), with: .color(Color(hex: 0xFFF6CC)))
            for i in 0..<4 {
                let cx = (hash(i + 90) * (W + 80) - scrollWrap(e.scroll * 0.04, W + 80)).truncatingRemainder(dividingBy: W + 80)
                let x = cx < -40 ? cx + W + 80 : cx
                let y = 12 + hash(i + 7) * 28
                ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: 26, height: 5), cornerRadius: 2.5), with: .color(.white.opacity(0.55)))
                ctx.fill(Path(roundedRect: CGRect(x: x + 6, y: y - 3, width: 14, height: 5), cornerRadius: 2.5), with: .color(.white.opacity(0.55)))
            }
        } else {
            for i in 0..<46 {
                let x = hash(i) * W, y = hash(i + 500) * (gy - 18)
                let tw = 0.35 + 0.65 * abs(sin(e.clock * 1.8 + CGFloat(i)))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.9, height: 0.9)), with: .color(.white.opacity(Double(tw))))
            }
            let m = CGPoint(x: W * 0.78, y: 24)
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 9, y: m.y - 9, width: 18, height: 18)), with: .color(pal.accent.opacity(0.18)))
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 6, y: m.y - 6, width: 12, height: 12)), with: .color(Color(hex: 0xEAF7FF)))
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 3.5, y: m.y - 7.5, width: 11, height: 11)), with: .color(pal.skyTop.opacity(0.92)))
        }

        // far skyline
        let colW: CGFloat = 18
        let farCam = e.scroll * 0.12
        let firstFar = Int(floor(farCam / colW)) - 1
        for i in firstFar...(firstFar + Int(W / colW) + 3) {
            let x = CGFloat(i) * colW - farCam
            let hh = 16 + hash(i &* 31) * 38
            if world == .real {
                ctx.fill(Path(CGRect(x: x, y: gy - hh, width: colW - 2, height: hh)), with: .color(pal.far.opacity(0.85)))
            } else {
                // hanging, inverted skyline
                ctx.fill(Path(CGRect(x: x, y: -5, width: colW - 2, height: hh * 0.8 + 5)), with: .color(pal.far.opacity(0.7)))
                ctx.fill(Path(CGRect(x: x, y: gy - hh * 0.6, width: colW - 2, height: hh * 0.6)), with: .color(pal.far.opacity(0.5)))
                for w in 0..<3 where hash(i * 7 + w) > 0.45 {
                    let flick = hash(i * 13 + w) > 0.8 ? (0.4 + 0.6 * abs(sin(e.clock * 3 + CGFloat(i)))) : 1
                    ctx.fill(Path(CGRect(x: x + 3 + CGFloat(w) * 5, y: hh * 0.8 - 6 - CGFloat(w % 2) * 6, width: 2, height: 2.4)),
                             with: .color(pal.accent.opacity(0.7 * Double(flick))))
                }
            }
        }

        // near layer
        let nearCam = e.scroll * 0.35
        let nColW: CGFloat = 26
        let firstNear = Int(floor(nearCam / nColW)) - 1
        for i in firstNear...(firstNear + Int(W / nColW) + 3) {
            let x = CGFloat(i) * nColW - nearCam
            let hh = 7 + hash(i &* 17 + 3) * 14
            if hash(i &* 5 + 1) < 0.35 { continue }
            if world == .real {
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: gy - hh - 2, width: 14, height: hh + 4)), with: .color(pal.near.opacity(0.9)))
            } else {
                var p = Path()
                p.move(to: CGPoint(x: x, y: gy))
                p.addLine(to: CGPoint(x: x + 5, y: gy - hh - 5))
                p.addLine(to: CGPoint(x: x + 9, y: gy - hh * 0.4))
                p.addLine(to: CGPoint(x: x + 13, y: gy - hh - 1))
                p.addLine(to: CGPoint(x: x + 17, y: gy))
                p.closeSubpath()
                ctx.fill(p, with: .color(pal.near.opacity(0.95)))
            }
        }

        drawCrowd(ctx, rc, world, pal)

        // ground
        let lava = e.event == .lava && world == .shadow
        let groundRect = CGRect(x: -60, y: gy, width: W + 120, height: 120)
        if lava {
            ctx.fill(Path(groundRect), with: .linearGradient(Gradient(colors: [Color(hex: 0xFF3D00), Color(hex: 0xFFB300)]),
                                                              startPoint: CGPoint(x: 0, y: gy), endPoint: CGPoint(x: 0, y: 100)))
            for i in 0..<14 {
                let bx = (hash(i + 1000) * W + e.clock * 3 * hash(i + 77)).truncatingRemainder(dividingBy: W)
                let ph = (e.clock * (0.6 + hash(i + 40)) + hash(i)).truncatingRemainder(dividingBy: 1)
                ctx.fill(Path(ellipseIn: CGRect(x: bx, y: gy + 22 - ph * 20, width: 2 + hash(i) * 3, height: 2 + hash(i) * 3)),
                         with: .color(Color(hex: 0xFFE082, opacity: Double(1 - ph))))
            }
            ctx.fill(Path(CGRect(x: -60, y: gy - 0.6, width: W + 120, height: 1.8)), with: .color(Color(hex: 0xFFD54F)))
        } else {
            ctx.fill(Path(groundRect), with: .linearGradient(Gradient(colors: [pal.ground, pal.ground.opacity(0.85)]),
                                                              startPoint: CGPoint(x: 0, y: gy), endPoint: CGPoint(x: 0, y: 100)))
            if world == .real {
                let off = e.scroll.truncatingRemainder(dividingBy: 16)
                var x = -off
                while x < W + 16 {
                    ctx.fill(Path(CGRect(x: x, y: gy + 5, width: 8, height: 1.4)), with: .color(pal.groundEdge.opacity(0.55)))
                    ctx.fill(Path(CGRect(x: x + 8, y: gy + 13, width: 6, height: 1.2)), with: .color(pal.groundEdge.opacity(0.4)))
                    x += 16
                }
                ctx.fill(Path(CGRect(x: -60, y: gy - 0.4, width: W + 120, height: 1.6)), with: .color(pal.groundEdge))
            } else {
                var glow = ctx
                glow.addFilter(.shadow(color: pal.groundEdge, radius: 3))
                glow.fill(Path(CGRect(x: -60, y: gy - 0.4, width: W + 120, height: 0.9)), with: .color(pal.groundEdge))
                let off = e.scroll.truncatingRemainder(dividingBy: 14)
                var x = -off
                while x < W + 28 {
                    var p = Path(); p.move(to: CGPoint(x: x + 7, y: gy)); p.addLine(to: CGPoint(x: x - 8 + (x - W / 2) * 0.3, y: 100))
                    ctx.stroke(p, with: .color(pal.groundEdge.opacity(0.28)), lineWidth: 0.4)
                    x += 14
                }
                for y in [gy + 6, gy + 13, gy + 22] {
                    ctx.fill(Path(CGRect(x: -60, y: y, width: W + 120, height: 0.35)), with: .color(pal.groundEdge.opacity(0.3)))
                }
            }
        }

        // coins
        for c in e.coins where !c.taken {
            let sx = c.x - e.scroll
            if sx < -6 || sx > W + 6 { continue }
            let bob = sin(e.clock * 4 + c.x) * 0.8
            let s: CGFloat = 2.5
            var d = Path()
            d.move(to: CGPoint(x: sx, y: c.y - s + bob)); d.addLine(to: CGPoint(x: sx + s * 0.75, y: c.y + bob))
            d.addLine(to: CGPoint(x: sx, y: c.y + s + bob)); d.addLine(to: CGPoint(x: sx - s * 0.75, y: c.y + bob)); d.closeSubpath()
            var g = ctx
            g.addFilter(.shadow(color: world == .real ? Color(hex: 0xFFB300) : pal.accent, radius: 2.5))
            g.fill(d, with: .color(world == .real ? Color(hex: 0xFFD54F) : Color(hex: 0x7DF9FF)))
        }

        // obstacles
        for o in e.obstacles {
            let sx = o.x - e.scroll
            if sx > W + 20 || sx + o.w < -20 { continue }
            let solid = o.world == world
            if !solid && e.cfg.modifier == .ghostTown { continue }
            drawObstacle(ctx, o, sx: sx, gy: gy, pal: pal, world: world, solid: solid, clock: e.clock)
        }

        drawPlayer(ctx, rc, world)
    }

    // MARK: Crowd (background people)

    static func drawCrowd(_ ctx: GraphicsContext, _ rc: RenderContext, _ world: World, _ pal: WorldPalette) {
        let e = rc.e
        let loop = rc.viewW + 70
        let backwards = e.event == .backwards
        let talking = e.event == .talking
        let color = world == .real ? Color(hex: 0x4A3B6B, opacity: 0.6) : Color(hex: 0xB89CFF, opacity: 0.55)
        let drift: CGFloat = backwards ? e.clock * 26 : 0
        for i in 0..<8 {
            var x = hash(i + 300) * loop - e.scroll * 0.55 + drift
            x = x.truncatingRemainder(dividingBy: loop)
            if x < 0 { x += loop }
            x -= 30
            let gy = e.groundY - 0.5
            let dir: CGFloat = backwards ? 1 : -1
            let step = sin(e.clock * 9 + CGFloat(i)) * 1.6 * (backwards ? -1 : 1)
            var body = Path(roundedRect: CGRect(x: x - 1.6, y: gy - 8, width: 3.2, height: 5.2), cornerRadius: 1.4)
            body.addEllipse(in: CGRect(x: x - 1.5 + dir * 0.3, y: gy - 11.2, width: 3, height: 3))
            ctx.fill(body, with: .color(color))
            var legs = Path()
            legs.move(to: CGPoint(x: x - 0.6, y: gy - 3)); legs.addLine(to: CGPoint(x: x - 0.6 + step, y: gy))
            legs.move(to: CGPoint(x: x + 0.6, y: gy - 3)); legs.addLine(to: CGPoint(x: x + 0.6 - step, y: gy))
            ctx.stroke(legs, with: .color(color), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            if talking && i % 3 == 0 && x > 10 && x < rc.viewW - 40 {
                let line = Quips.speech[(i + Int(e.clock / 2.4)) % Quips.speech.count]
                let w = CGFloat(line.count) * 1.75 + 5
                let bubble = CGRect(x: x - w / 2, y: gy - 24, width: w, height: 8)
                ctx.fill(Path(roundedRect: bubble, cornerRadius: 3), with: .color(.white.opacity(0.95)))
                var tail = Path()
                tail.move(to: CGPoint(x: x - 1.5, y: gy - 16.2)); tail.addLine(to: CGPoint(x: x, y: gy - 13.2)); tail.addLine(to: CGPoint(x: x + 1.5, y: gy - 16.2))
                ctx.fill(tail, with: .color(.white.opacity(0.95)))
                ctx.draw(Text(line).font(.system(size: 3.6, weight: .heavy, design: .rounded)).foregroundColor(Color(hex: 0x1B1633)),
                         at: CGPoint(x: x, y: gy - 20), anchor: .center)
            }
        }
    }

    // MARK: Obstacle

    static func drawObstacle(_ context: GraphicsContext, _ o: Obstacle, sx: CGFloat, gy: CGFloat, pal: WorldPalette,
                             world: World, solid: Bool, clock: CGFloat) {
        var ctx = context
        let h = o.h
        let rect = CGRect(x: sx, y: gy - h, width: o.w, height: h)
        if !solid {
            let ghost = Path(roundedRect: rect, cornerRadius: 1.5)
            ctx.stroke(ghost, with: .color(pal.obstacleEdge.opacity(0.28)), style: StrokeStyle(lineWidth: 0.6, dash: [1.6, 1.6]))
            ctx.fill(ghost, with: .color(pal.obstacleEdge.opacity(0.05)))
            return
        }
        if world == .real {
            let body = Path(roundedRect: rect, cornerRadius: 1.2)
            ctx.fill(body, with: .linearGradient(Gradient(colors: [pal.obstacle, pal.obstacle.opacity(0.82)]),
                                                 startPoint: CGPoint(x: 0, y: rect.minY), endPoint: CGPoint(x: 0, y: rect.maxY)))
            var deco = Path()
            switch o.kind % 4 {
            case 0:
                deco.move(to: CGPoint(x: rect.minX, y: rect.minY)); deco.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                deco.move(to: CGPoint(x: rect.maxX, y: rect.minY)); deco.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            case 1:
                var x = rect.minX
                while x < rect.maxX - 1 {
                    deco.move(to: CGPoint(x: x, y: rect.minY + 3)); deco.addLine(to: CGPoint(x: min(x + 2, rect.maxX), y: rect.minY - 3.5))
                    deco.addLine(to: CGPoint(x: min(x + 4, rect.maxX), y: rect.minY + 3))
                    x += 4
                }
            case 2:
                var y = rect.minY + 5
                while y < rect.maxY { deco.move(to: CGPoint(x: rect.minX, y: y)); deco.addLine(to: CGPoint(x: rect.maxX, y: y)); y += 5 }
                deco.addRect(CGRect(x: rect.minX - 1, y: rect.minY - 1.6, width: rect.width + 2, height: 2.2))
            default:
                var x = rect.minX - h
                while x < rect.maxX {
                    deco.move(to: CGPoint(x: x, y: rect.maxY)); deco.addLine(to: CGPoint(x: x + h, y: rect.minY))
                    x += 5
                }
            }
            var clipped = ctx
            clipped.clip(to: Path(roundedRect: rect.insetBy(dx: -0.3, dy: -4), cornerRadius: 1))
            if o.kind % 4 == 1 {
                clipped.fill(deco, with: .color(pal.obstacle))
                clipped.stroke(deco, with: .color(pal.obstacleEdge), lineWidth: 0.7)
            } else {
                var inner = ctx
                inner.clip(to: Path(roundedRect: rect, cornerRadius: 1.2))
                inner.stroke(deco, with: .color(pal.obstacleEdge.opacity(0.75)), style: StrokeStyle(lineWidth: o.kind % 4 == 3 ? 1.6 : 0.9, lineJoin: .round))
            }
            ctx.stroke(body, with: .color(pal.obstacleEdge), lineWidth: 0.9)
        } else {
            // glowing shadow crystal
            var p = Path()
            let teeth = max(2, Int(o.w / 4.5))
            let tw = o.w / CGFloat(teeth)
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            for i in 0..<teeth {
                let x0 = rect.minX + CGFloat(i) * tw
                let tall = hash(Int(o.x * 10) + i * 3) > 0.35
                p.addLine(to: CGPoint(x: x0, y: rect.minY + (tall ? 3.5 : 7)))
                p.addLine(to: CGPoint(x: x0 + tw / 2, y: rect.minY - (tall ? 0.5 : -2)))
            }
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 5))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
            var g = ctx
            g.addFilter(.shadow(color: pal.obstacle, radius: 4))
            g.fill(p, with: .linearGradient(Gradient(colors: [pal.obstacle.opacity(0.85), pal.obstacle.opacity(0.2)]),
                                            startPoint: CGPoint(x: 0, y: rect.minY), endPoint: CGPoint(x: 0, y: rect.maxY)))
            g.stroke(p, with: .color(pal.obstacleEdge), style: StrokeStyle(lineWidth: 0.8, lineJoin: .round))
            var facets = Path()
            facets.move(to: CGPoint(x: rect.minX + o.w * 0.3, y: rect.maxY)); facets.addLine(to: CGPoint(x: rect.minX + o.w * 0.45, y: rect.minY + 6))
            facets.move(to: CGPoint(x: rect.minX + o.w * 0.7, y: rect.maxY)); facets.addLine(to: CGPoint(x: rect.minX + o.w * 0.6, y: rect.minY + 8))
            ctx.stroke(facets, with: .color(pal.obstacleEdge.opacity(0.5)), lineWidth: 0.4)
        }
    }

    // MARK: Player

    static func drawPlayer(_ context: GraphicsContext, _ rc: RenderContext, _ world: World) {
        let e = rc.e
        if e.phase == .dead { return }
        var ctx = context
        let skin = rc.skin
        let px = e.playerX, gy = e.groundY
        let running = e.phase == .running
        let bob: CGFloat = running ? abs(sin(e.clock * 14)) * 1.1 : 0
        let body = world == .real ? Color(hex: skin.real) : Color(hex: skin.shadow)
        let eye = world == .real ? Color.white : Color(hex: 0x120828)
        let accent = world == .real ? Color(hex: skin.shadow) : Color(hex: skin.real).opacity(0.9)

        if e.invuln > 0 && Int(e.clock * 14) % 2 == 0 { ctx.opacity = 0.4 }
        let s = e.squash
        let cx = px + playerHalf, base = gy
        ctx.translateBy(x: cx, y: base)
        ctx.scaleBy(x: 1 + 0.32 * s, y: 1 - 0.26 * s)
        ctx.translateBy(x: -cx, y: -base)
        if world == .shadow { ctx.addFilter(.shadow(color: body.opacity(0.9), radius: 3.5)) }

        // scarf
        var scarf = Path()
        let wave = sin(e.clock * 12) * 1.4
        scarf.move(to: CGPoint(x: px + 1.2, y: gy - 8 - bob))
        scarf.addQuadCurve(to: CGPoint(x: px - 6, y: gy - 8.5 - bob + wave), control: CGPoint(x: px - 2.5, y: gy - 6 - bob - wave))
        ctx.stroke(scarf, with: .color(accent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // legs
        let st = running ? sin(e.clock * 14) * 2.6 : 0
        var legs = Path()
        legs.move(to: CGPoint(x: px + 2.4, y: gy - 3.2 - bob)); legs.addLine(to: CGPoint(x: px + 2.4 + st, y: gy - max(0, -st) * 0.35))
        legs.move(to: CGPoint(x: px + 4.6, y: gy - 3.2 - bob)); legs.addLine(to: CGPoint(x: px + 4.6 - st, y: gy - max(0, st) * 0.35))
        ctx.stroke(legs, with: .color(body), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))

        // body
        let bodyRect = CGRect(x: px + 0.3, y: gy - 11.2 - bob, width: 6.4, height: 8.6)
        ctx.fill(Path(roundedRect: bodyRect, cornerRadius: 3.2), with: .color(body))
        // eyes
        ctx.fill(Path(ellipseIn: CGRect(x: px + 3.4, y: gy - 8.8 - bob, width: 1.3, height: 1.8)), with: .color(eye))
        ctx.fill(Path(ellipseIn: CGRect(x: px + 5.1, y: gy - 8.8 - bob, width: 1.3, height: 1.8)), with: .color(eye))

        // accessory
        let top = gy - 11.2 - bob
        var acc = Path()
        switch skin.accessory {
        case .none: break
        case .catEars:
            acc.move(to: CGPoint(x: px + 0.6, y: top + 2)); acc.addLine(to: CGPoint(x: px + 1.2, y: top - 2.6)); acc.addLine(to: CGPoint(x: px + 3, y: top + 0.6))
            acc.move(to: CGPoint(x: px + 4, y: top + 0.6)); acc.addLine(to: CGPoint(x: px + 5.8, y: top - 2.6)); acc.addLine(to: CGPoint(x: px + 6.4, y: top + 2))
            ctx.fill(acc, with: .color(body))
        case .horns:
            acc.move(to: CGPoint(x: px + 1, y: top + 1.5)); acc.addQuadCurve(to: CGPoint(x: px - 0.4, y: top - 3.4), control: CGPoint(x: px - 0.6, y: top - 0.4))
            acc.addQuadCurve(to: CGPoint(x: px + 2.6, y: top + 0.4), control: CGPoint(x: px + 1.8, y: top - 1.6))
            acc.move(to: CGPoint(x: px + 6, y: top + 1.5)); acc.addQuadCurve(to: CGPoint(x: px + 7.4, y: top - 3.4), control: CGPoint(x: px + 7.6, y: top - 0.4))
            acc.addQuadCurve(to: CGPoint(x: px + 4.4, y: top + 0.4), control: CGPoint(x: px + 5.2, y: top - 1.6))
            ctx.fill(acc, with: .color(accent))
        case .crown:
            acc.move(to: CGPoint(x: px + 0.8, y: top + 1)); acc.addLine(to: CGPoint(x: px + 0.8, y: top - 3)); acc.addLine(to: CGPoint(x: px + 2.3, y: top - 1))
            acc.addLine(to: CGPoint(x: px + 3.5, y: top - 3.8)); acc.addLine(to: CGPoint(x: px + 4.7, y: top - 1)); acc.addLine(to: CGPoint(x: px + 6.2, y: top - 3))
            acc.addLine(to: CGPoint(x: px + 6.2, y: top + 1)); acc.closeSubpath()
            ctx.fill(acc, with: .color(Color(hex: 0xFFD54F)))
        case .halo:
            ctx.stroke(Path(ellipseIn: CGRect(x: px + 0.8, y: top - 4.2 + sin(e.clock * 4) * 0.4, width: 5.8, height: 2)),
                       with: .color(Color(hex: skin.shadow)), lineWidth: 0.9)
        case .antenna:
            acc.move(to: CGPoint(x: px + 3.5, y: top + 0.6)); acc.addLine(to: CGPoint(x: px + 3.9, y: top - 3.6))
            ctx.stroke(acc, with: .color(body), lineWidth: 0.7)
            ctx.fill(Path(ellipseIn: CGRect(x: px + 2.9, y: top - 5.4, width: 2, height: 2)), with: .color(Color(hex: skin.shadow)))
        case .cap:
            var cap = Path()
            cap.addArc(center: CGPoint(x: px + 3.5, y: top + 1.6), radius: 3.4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            cap.closeSubpath()
            ctx.fill(cap, with: .color(accent))
            ctx.fill(Path(roundedRect: CGRect(x: px + 4.6, y: top + 0.9, width: 4, height: 1), cornerRadius: 0.5), with: .color(accent))
        case .bunny:
            ctx.fill(Path(ellipseIn: CGRect(x: px + 0.8, y: top - 7, width: 2, height: 7.6)), with: .color(body))
            ctx.fill(Path(ellipseIn: CGRect(x: px + 4, y: top - 7.4, width: 2, height: 8)), with: .color(body))
        }
    }

    static let playerHalf: CGFloat = 3.5

    // MARK: Overlays

    static func drawParticles(_ ctx: GraphicsContext, _ rc: RenderContext) {
        for p in rc.e.particles {
            let a = max(0, p.life / p.maxLife)
            var c = ctx
            c.opacity = Double(a)
            let r = p.size * (0.4 + 0.6 * a)
            c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(p.color))
        }
    }

    static func drawPopups(_ ctx: GraphicsContext, _ rc: RenderContext) {
        for p in rc.e.popups {
            var c = ctx
            c.opacity = Double(min(1, p.life * 2.5))
            c.draw(Text(p.text).font(.system(size: 5, weight: .black, design: .rounded)).foregroundColor(p.color),
                   at: CGPoint(x: p.x + 20, y: p.y), anchor: .center)
        }
    }

    static func drawSpeedLines(_ ctx: GraphicsContext, _ rc: RenderContext) {
        let e = rc.e
        for i in 0..<14 {
            let y = hash(i + 700) * 90 + 2
            let x = (hash(i + 800) * rc.viewW * 1.4 - e.clock * 360 * (0.6 + hash(i))).truncatingRemainder(dividingBy: rc.viewW * 1.4)
            let xx = x < 0 ? x + rc.viewW * 1.4 : x
            ctx.fill(Path(CGRect(x: xx - 20, y: y, width: 26 + hash(i) * 20, height: 0.35)), with: .color(.white.opacity(0.4)))
        }
    }

    static func scrollWrap(_ v: CGFloat, _ m: CGFloat) -> CGFloat { v.truncatingRemainder(dividingBy: m) }
}
