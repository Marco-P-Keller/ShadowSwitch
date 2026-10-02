import SwiftUI

enum ActivePanel: Identifiable {
    case daily, pass, skins, worlds, shards, settings
    var id: Int { hashValue }
}

// MARK: - Canvas host

struct GameCanvasView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject var progress: PlayerData
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let paused = session.screen == .paused
        TimelineView(.animation(minimumInterval: nil, paused: paused)) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate
            let _ = session.engine.advance(to: now)
            Canvas(rendersAsynchronously: false) { ctx, size in
                _ = now   // capture the frame time so SwiftUI re-runs the closure every frame
                Renderer.draw(ctx, size: size, e: session.engine, theme: progress.theme, skin: progress.skin,
                              reduceFX: progress.d.reduceFX || reduceMotion)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - HUD

struct HUDView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject var progress: PlayerData

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
            let e = session.engine
            ZStack {
                VStack(spacing: 6) {
                    HStack(alignment: .top) {
                        Button { Sfx.play(.tap); session.pause() } label: {
                            Image(systemName: "pause.fill").font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                                .frame(width: 40, height: 40).background(.black.opacity(0.35), in: Circle())
                                .overlay(Circle().strokeBorder(UI.stroke))
                        }
                        .accessibilityLabel("Pause")
                        Spacer()
                        VStack(spacing: 0) {
                            Text("\(e.score)").font(UI.title(44)).foregroundStyle(.white).monospacedDigit()
                                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                            Text("BEST \(max(progress.d.best, e.score))").font(UI.body(11, .heavy)).tracking(1.5).shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Pill(icon: "diamond.fill", text: "\(e.coinsCollected)")
                            if e.chain > 0 {
                                Text("CHAIN ×\(e.chain)").font(UI.title(13)).foregroundStyle(.black)
                                    .padding(.horizontal, 10).padding(.vertical, 4).background(UI.gold, in: Capsule())
                                    .transition(.scale)
                            }
                        }
                    }
                    if let b = e.banner {
                        VStack(spacing: 2) {
                            Text(b).font(UI.title(18)).tracking(1).foregroundStyle(.white)
                            if let ev = e.event { Text(ev.tip).font(UI.body(11)).foregroundStyle(.white.opacity(0.8)) }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(LinearGradient(colors: [UI.pink, UI.violet], startPoint: .leading, endPoint: .trailing), in: Capsule())
                        .shadow(color: UI.pink.opacity(0.5), radius: 12)
                        .opacity(Double(min(1, e.bannerLife * 2)))
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        worldBadge(e.world)
                        if session.progress.d.reduceFX == false, e.event == .lava {
                            heatBar(e.heat / 1.8)
                        } else if e.event == .lava { heatBar(e.heat / 1.8) }
                        Spacer()
                        if e.cfg.modifier == .switchBudget { tokens(e.tokens) }
                        if let m = e.cfg.modifier {
                            Label(m.title, systemImage: m.icon).font(UI.body(12, .heavy)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5).background(.black.opacity(0.35), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 6)

                if !progress.d.tutorialDone && session.screen == .playing && e.t < 9 && e.switches < 3 {
                    VStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill").font(.system(size: 30)).foregroundStyle(.white)
                        Text("TAP ANYWHERE TO SWITCH WORLDS").font(UI.title(14)).tracking(1).foregroundStyle(.white)
                        Text("Solid obstacles only hurt in their own world").font(UI.body(11)).foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(14).background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                    .offset(y: 40)
                    .opacity(0.5 + 0.5 * abs(sin(Double(e.clock) * 3)))
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
    }

    func worldBadge(_ w: World) -> some View {
        HStack(spacing: 6) {
            Circle().fill(w == .real ? Color(hex: 0xFFB36B) : UI.cyan).frame(width: 9, height: 9)
            Text("\(w.title) WORLD").font(UI.title(12)).tracking(1.5).foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 6).background(.black.opacity(0.4), in: Capsule())
    }

    func heatBar(_ v: CGFloat) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(Color(hex: 0xFF6B1A))
            ZStack(alignment: .leading) {
                Capsule().fill(.black.opacity(0.4))
                Capsule().fill(LinearGradient(colors: [UI.gold, Color(hex: 0xFF3D00)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 110 * min(1, max(0, v)))
            }.frame(width: 110, height: 9)
        }
        .padding(.horizontal, 10).padding(.vertical, 5).background(.black.opacity(0.4), in: Capsule())
    }

    func tokens(_ v: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "bolt.fill").font(.system(size: 14))
                    .foregroundStyle(v >= CGFloat(i + 1) ? UI.gold : .white.opacity(0.25))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5).background(.black.opacity(0.4), in: Capsule())
    }
}

// MARK: - Pause

struct PauseView: View {
    @ObservedObject var session: GameSession
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                GradientTitle(text: "PAUSED", size: 38)
                Button { session.resume() } label: { Label("RESUME", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                HStack(spacing: 12) {
                    Button { session.retry() } label: { Label("Restart", systemImage: "arrow.clockwise") }.buttonStyle(GlassButtonStyle())
                    Button { session.home() } label: { Label("Home", systemImage: "house.fill") }.buttonStyle(GlassButtonStyle())
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Death

struct DeathView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject var progress: PlayerData
    @State private var appear = false

    var body: some View {
        let r = session.result
        ZStack {
            Color.black.opacity(appear ? 0.62 : 0).ignoresSafeArea()
            HStack(alignment: .center, spacing: 22) {
                // score card
                VStack(alignment: .leading, spacing: 8) {
                    if r.newBest {
                        Text("★ NEW BEST").font(UI.title(13)).tracking(2).foregroundStyle(.black)
                            .padding(.horizontal, 10).padding(.vertical, 4).background(UI.gold, in: Capsule())
                    } else if let t = r.challengeTarget {
                        Text(r.challengeBeaten ? "CHALLENGE BEATEN!" : "TARGET \(t)").font(UI.title(13)).tracking(2)
                            .foregroundStyle(r.challengeBeaten ? .black : .white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(r.challengeBeaten ? UI.cyan : Color.white.opacity(0.15), in: Capsule())
                    } else {
                        Text("YOU DIED").font(UI.title(13)).tracking(2).foregroundStyle(.white.opacity(0.7))
                    }
                    Text("\(r.score)").font(UI.title(64)).foregroundStyle(.white).monospacedDigit()
                        .contentTransition(.numericText())
                    Text("“\(r.cause)”").font(.system(size: 14, weight: .semibold, design: .rounded)).italic()
                        .foregroundStyle(UI.sub).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Pill(icon: "diamond.fill", text: "+\(r.shards)")
                        Pill(icon: "bolt.fill", text: "\(r.closeCalls) close", tint: UI.cyan)
                        Pill(icon: "star.fill", text: "+\(r.xp) XP", tint: UI.violet)
                    }
                    xpBar(r)
                    if r.mode == .daily {
                        Label(progress.dailyDone ? (r.dailyCompleted ? "Daily complete! +150 shards" : "Daily complete ✓")
                              : "Daily goal \(progress.dailyGoal) · best \(progress.dailyBestToday)",
                              systemImage: "calendar").font(UI.body(12, .bold)).foregroundStyle(UI.cyan)
                    }
                    if r.challengeBeaten && progress.d.rivalUnlocked {
                        Label("Unlocked skin: Rival", systemImage: "gift.fill").font(UI.body(12, .bold)).foregroundStyle(UI.gold)
                    }
                }
                .frame(maxWidth: 340, alignment: .leading)

                VStack(spacing: 12) {
                    Button { session.retry() } label: { Label("RETRY", systemImage: "arrow.clockwise").frame(minWidth: 150) }
                        .buttonStyle(PrimaryButtonStyle(size: 24))
                    if !session.engine.revived {
                        Button { session.revive() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill").foregroundStyle(UI.pink)
                                Text("Second Chance")
                                Text(progress.d.revives > 0 ? "×\(progress.d.revives)" : "\(GameSession.reviveCost)◆")
                                    .foregroundStyle(UI.gold)
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(!session.canReviveNow())
                        .opacity(session.canReviveNow() ? 1 : 0.4)
                    }
                    HStack(spacing: 10) {
                        shareButton
                        Button { session.home() } label: { Image(systemName: "house.fill") }.buttonStyle(GlassButtonStyle())
                            .accessibilityLabel("Home")
                    }
                }
            }
            .padding(24)
            .scaleEffect(appear ? 1 : 0.92).opacity(appear ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55)) { appear = true } }
    }

    @ViewBuilder var shareButton: some View {
        if let img = session.cardImage {
            ShareLink(item: Image(uiImage: img), message: Text(session.shareText()),
                      preview: SharePreview("My Shadow Switch death", image: Image(uiImage: img))) {
                Label("Share death", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    func xpBar(_ r: RunResult) -> some View {
        let tier = progress.passTier
        let into = progress.d.xp - tier * Pass.xpPerTier
        let frac = tier >= Pass.maxTier ? 1 : CGFloat(into) / CGFloat(Pass.xpPerTier)
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("SHADOW PASS · TIER \(tier)").font(UI.body(10, .heavy)).tracking(1.2).foregroundStyle(UI.sub)
                if r.tierAfter > r.tierBefore { Text("TIER UP!").font(UI.title(10)).foregroundStyle(UI.gold) }
            }
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule().fill(LinearGradient(colors: [UI.cyan, UI.violet], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 220 * frac)
            }.frame(width: 220, height: 7)
        }
    }
}
