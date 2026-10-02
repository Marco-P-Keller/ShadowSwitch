import SwiftUI

// MARK: - Skin figure preview

enum PreviewHost {
    static let engine: GameEngine = {
        let e = GameEngine()
        e.phase = .running
        return e
    }()
}

struct SkinFigure: View {
    let skin: Skin
    var world: World
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in
            Canvas { ctx, size in
                let e = PreviewHost.engine
                e.clock = CGFloat(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))
                e.squash = 0; e.invuln = 0
                let rc = RenderContext(e: e, theme: Catalog.themes[0], skin: skin, viewW: 100, reduceFX: false)
                let k = min(size.width / 20, size.height / 20)
                var c = ctx
                c.translateBy(x: size.width / 2, y: size.height * 0.92)
                c.scaleBy(x: k, y: k)
                c.translateBy(x: -(e.playerX + 3.5), y: -e.groundY)
                Renderer.drawPlayer(c, rc, world)
            }
        }
    }
}

struct StaticSkinFigure: View {
    let skin: Skin
    let world: World
    var body: some View {
        Canvas { ctx, size in
            let e = PreviewHost.engine
            e.clock = 0.3; e.squash = 0; e.invuln = 0
            let rc = RenderContext(e: e, theme: Catalog.themes[0], skin: skin, viewW: 100, reduceFX: false)
            let k = min(size.width / 20, size.height / 20)
            var c = ctx
            c.translateBy(x: size.width / 2, y: size.height * 0.92)
            c.scaleBy(x: k, y: k)
            c.translateBy(x: -(e.playerX + 3.5), y: -e.groundY)
            Renderer.drawPlayer(c, rc, world)
        }
    }
}

// MARK: - Shop (skins / worlds / shards)

struct ShopPanel: View {
    enum Tab: String, CaseIterable { case skins = "Skins", worlds = "Worlds", shards = "Shop" }
    @State var tab: Tab
    let onClose: () -> Void
    var openPass: () -> Void
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var store: Store

    var body: some View {
        Panel(title: "Shop", subtitle: "Cosmetics only. Never pay-to-win.", onClose: onClose) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Tab.allCases, id: \.self) { t in
                        Button { Sfx.play(.tap); withAnimation(.snappy) { tab = t } } label: {
                            Text(t.rawValue.uppercased()).font(UI.title(12)).tracking(1)
                                .foregroundStyle(tab == t ? .black : .white)
                                .padding(.horizontal, 16).padding(.vertical, 7)
                                .background(tab == t ? AnyShapeStyle(.white) : AnyShapeStyle(UI.glass), in: Capsule())
                        }
                    }
                    Spacer()
                    Pill(icon: "diamond.fill", text: "\(progress.d.shards)")
                }
                .padding(.horizontal, 20)
                ScrollView {
                    Group {
                        switch tab {
                        case .skins: skinGrid
                        case .worlds: worldGrid
                        case .shards: shardShop
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 16)
                }
            }
        }
    }

    var skinGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 10)], spacing: 10) {
            ForEach(Catalog.skins) { s in skinCard(s) }
        }
    }

    func skinCard(_ s: Skin) -> some View {
        let owned = progress.owns(skin: s.id)
        let equipped = progress.d.skin == s.id
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color(hex: 0xFFD9B0), Color(hex: 0x2A1457)], startPoint: .topLeading, endPoint: .bottomTrailing))
                SkinFigure(skin: s, world: .shadow).padding(6).opacity(owned ? 1 : 0.55)
                if !owned { Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.8)).font(.system(size: 14)) }
            }.frame(height: 74)
            Text(s.name).font(UI.title(13)).foregroundStyle(.white).lineLimit(1)
            Text(s.rarity.rawValue.uppercased()).font(UI.body(9, .heavy)).tracking(1).foregroundStyle(s.rarity.color)
            Button {
                if owned { progress.d.skin = s.id; Sfx.play(.tap) }
                else if progress.buy(skin: s) { Sfx.play(.reward) }
                else { Sfx.play(.tap) }
            } label: {
                Group {
                    if equipped { Text("EQUIPPED") }
                    else if owned { Text("EQUIP") }
                    else if s.price > 0 { Text("\(s.price) ◆") }
                    else { Text(s.unlockHint).font(UI.body(9, .bold)).multilineTextAlignment(.center) }
                }
                .font(UI.title(11)).foregroundStyle(equipped ? .white : .black)
                .frame(maxWidth: .infinity, minHeight: 26)
                .background(equipped ? AnyShapeStyle(UI.violet) : AnyShapeStyle(owned || s.price > 0 ? UI.gold : Color.white.opacity(0.7)),
                            in: Capsule())
            }
            .disabled(equipped || (!owned && s.price == 0) || (!owned && progress.d.shards < s.price))
            .opacity((!owned && s.price > 0 && progress.d.shards < s.price) ? 0.5 : 1)
        }
        .padding(8)
        .background(UI.glass, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(equipped ? UI.violet : UI.stroke, lineWidth: equipped ? 2 : 1))
    }

    var worldGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
            ForEach(Catalog.themes) { t in themeCard(t) }
        }
    }

    func themeCard(_ t: Theme) -> some View {
        let owned = progress.owns(theme: t.id)
        let equipped = progress.d.theme == t.id
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                LinearGradient(colors: [t.real.skyTop, t.real.skyBottom], startPoint: .top, endPoint: .bottom)
                    .overlay(alignment: .bottom) { Rectangle().fill(t.real.ground).frame(height: 16) }
                LinearGradient(colors: [t.shadow.skyTop, t.shadow.skyBottom], startPoint: .top, endPoint: .bottom)
                    .overlay(alignment: .bottom) { Rectangle().fill(t.shadow.ground).frame(height: 16).overlay(alignment: .top) { Rectangle().fill(t.shadow.groundEdge).frame(height: 1.5) } }
            }
            .frame(height: 70).clipShape(RoundedRectangle(cornerRadius: 12))
            Text(t.name).font(UI.title(15)).foregroundStyle(.white)
            Text(t.blurb).font(UI.body(11)).foregroundStyle(UI.sub).lineLimit(2).frame(height: 28, alignment: .top)
            Button {
                if owned { progress.d.theme = t.id; Sfx.play(.tap) }
                else if progress.buy(theme: t) { Sfx.play(.reward) }
            } label: {
                Group {
                    if equipped { Text("ACTIVE") }
                    else if owned { Text("USE") }
                    else if t.price > 0 { Text("\(t.price) ◆") }
                    else { Text(t.unlockHint) }
                }
                .font(UI.title(12)).foregroundStyle(equipped ? .white : .black)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(equipped ? AnyShapeStyle(UI.violet) : AnyShapeStyle(owned || t.price > 0 ? UI.gold : Color.white.opacity(0.7)), in: Capsule())
            }
            .disabled(equipped || (!owned && t.price == 0) || (!owned && progress.d.shards < t.price))
            .opacity((!owned && t.price > 0 && progress.d.shards < t.price) ? 0.5 : 1)
        }
        .padding(10)
        .background(UI.glass, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(equipped ? UI.violet : UI.stroke, lineWidth: equipped ? 2 : 1))
    }

    var shardShop: some View {
        VStack(spacing: 10) {
            if !progress.d.starterBought {
                offer(icon: "gift.fill", title: "Starter Bundle", detail: "Neon Fox skin · 1000 shards · 3 second chances",
                      tag: "ONE-TIME OFFER", id: ProductID.starter, highlight: true)
            }
            Button { Sfx.play(.tap); onClose(); openPass() } label: {
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(UI.gold)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(progress.d.passPremium ? "Shadow Pass Premium · active" : "Shadow Pass · Season 1").font(UI.title(15)).foregroundStyle(.white)
                        Text("20 tiers · 3 exclusive skins · Haunted world").font(UI.body(11)).foregroundStyle(UI.sub)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(UI.sub)
                }
                .padding(12).background(UI.glass, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(UI.stroke))
            }
            .buttonStyle(.plain)
            offer(icon: "diamond.fill", title: "600 Shards", detail: "A handful of shiny cosmetics money.", tag: nil, id: ProductID.shardsS, highlight: false)
            offer(icon: "diamond.fill", title: "4000 Shards", detail: "Best value · 40% more per dollar.", tag: "BEST VALUE", id: ProductID.shardsL, highlight: false)
            HStack {
                Button { Task { await store.restore() } } label: { Label("Restore Purchases", systemImage: "arrow.clockwise") }
                    .buttonStyle(GlassButtonStyle(size: 12))
                Spacer()
            }
            if let m = store.message { Text(m).font(UI.body(12)).foregroundStyle(UI.gold) }
        }
    }

    func offer(icon: String, title: String, detail: String, tag: String?, id: String, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(UI.gold)
                .frame(width: 44, height: 44).background(UI.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(UI.title(16)).foregroundStyle(.white)
                    if let tag { Text(tag).font(UI.body(9, .heavy)).tracking(1).foregroundStyle(.black).padding(.horizontal, 6).padding(.vertical, 2).background(UI.gold, in: Capsule()) }
                }
                Text(detail).font(UI.body(12)).foregroundStyle(UI.sub)
            }
            Spacer()
            Button { Task { await store.buy(id) } } label: {
                Text(store.price(id)).font(UI.title(15)).foregroundStyle(.black)
                    .padding(.horizontal, 16).padding(.vertical, 8).background(UI.gold, in: Capsule())
            }
            .disabled(store.busy)
        }
        .padding(12)
        .background(highlight ? AnyShapeStyle(LinearGradient(colors: [UI.violet.opacity(0.5), UI.pink.opacity(0.35)], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(UI.glass),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(highlight ? UI.gold.opacity(0.6) : UI.stroke))
    }
}

// MARK: - Shadow Pass

struct PassPanel: View {
    let onClose: () -> Void
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var store: Store

    var body: some View {
        let tier = progress.passTier
        let into = progress.d.xp - tier * Pass.xpPerTier
        Panel(title: "Shadow Pass", subtitle: "Season 1 · \(Pass.seasonName)", onClose: onClose) {
            VStack(spacing: 10) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TIER \(tier) / \(Pass.maxTier)").font(UI.title(15)).foregroundStyle(.white)
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.12))
                            Capsule().fill(LinearGradient(colors: [UI.cyan, UI.violet], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 240 * (tier >= Pass.maxTier ? 1 : CGFloat(into) / CGFloat(Pass.xpPerTier)))
                        }.frame(width: 240, height: 8)
                        Text("Earn XP in every run. \(Pass.xpPerTier) XP per tier.").font(UI.body(11)).foregroundStyle(UI.sub)
                    }
                    Spacer()
                    if progress.d.passPremium {
                        Label("PREMIUM ACTIVE", systemImage: "checkmark.seal.fill").font(UI.title(12)).foregroundStyle(UI.gold)
                    } else {
                        Button { Task { await store.buy(ProductID.pass) } } label: {
                            VStack(spacing: 0) {
                                Text("UNLOCK PREMIUM").font(UI.title(13))
                                Text(store.price(ProductID.pass) + " · one time").font(UI.body(10, .bold))
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(colors: [UI.gold, Color(hex: 0xFF9F1C)], size: 14))
                        .foregroundStyle(.black)
                        .disabled(store.busy)
                    }
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("").frame(height: 18)
                            Text("FREE").font(UI.body(10, .heavy)).tracking(1.5).foregroundStyle(UI.sub).frame(width: 60, height: 76, alignment: .trailing)
                            Text("PREMIUM").font(UI.body(10, .heavy)).tracking(1.5).foregroundStyle(UI.gold).frame(width: 60, height: 76, alignment: .trailing)
                        }
                        ForEach(Pass.tiers) { t in tierColumn(t) }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 14)
                }
                if let m = store.message { Text(m).font(UI.body(12)).foregroundStyle(UI.gold) }
            }
        }
    }

    func tierColumn(_ t: PassTier) -> some View {
        let reached = progress.passTier >= t.tier
        return VStack(spacing: 8) {
            Text("\(t.tier)").font(UI.title(13)).foregroundStyle(reached ? UI.cyan : UI.sub).frame(height: 18)
            rewardCell(t, premium: false)
            rewardCell(t, premium: true)
        }
    }

    func rewardCell(_ t: PassTier, premium: Bool) -> some View {
        let reward = premium ? t.premium : t.free
        let claimed = premium ? progress.d.claimedPremium.contains(t.tier) : progress.d.claimedFree.contains(t.tier)
        let can = progress.canClaim(tier: t, premium: premium)
        let locked = premium && !progress.d.passPremium
        return Button {
            if can { progress.claim(tier: t, premium: premium); Sfx.play(.reward) }
        } label: {
            VStack(spacing: 4) {
                if let r = reward {
                    if case .skin(let id) = r {
                        StaticSkinFigure(skin: Catalog.skin(id), world: .shadow).frame(width: 36, height: 34)
                    } else {
                        Image(systemName: r.icon).font(.system(size: 20, weight: .bold))
                            .foregroundStyle(premium ? UI.gold : UI.cyan).frame(height: 34)
                    }
                    Text(r.label).font(UI.body(10, .heavy)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                } else {
                    Image(systemName: "minus").foregroundStyle(.white.opacity(0.2))
                }
            }
            .frame(width: 66, height: 76)
            .background(can ? AnyShapeStyle(LinearGradient(colors: [UI.violet.opacity(0.7), UI.pink.opacity(0.5)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(UI.glass),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(can ? UI.gold : UI.stroke, lineWidth: can ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if claimed { Image(systemName: "checkmark.circle.fill").foregroundStyle(UI.cyan).padding(3) }
                else if locked && reward != nil { Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(.white.opacity(0.6)).padding(5) }
            }
            .opacity(claimed ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!can)
    }
}

// MARK: - Daily

struct DailyPanel: View {
    let onClose: () -> Void
    let startDaily: () -> Void
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var session: GameSession
    @State private var code = ""

    var body: some View {
        let m = progress.dailyModifier
        Panel(title: "Daily", subtitle: "A new twist every day", onClose: onClose) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: m.icon).font(.system(size: 28, weight: .bold)).foregroundStyle(UI.cyan)
                            .frame(width: 56, height: 56).background(UI.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.title).font(UI.title(22)).foregroundStyle(.white)
                            Text(m.detail).font(UI.body(12)).foregroundStyle(UI.sub).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(spacing: 8) {
                        Pill(icon: "flag.checkered", text: "Goal \(progress.dailyGoal)", tint: UI.cyan)
                        Pill(icon: "trophy.fill", text: "Today's best \(progress.dailyBestToday)")
                        Pill(icon: "diamond.fill", text: "+150")
                    }
                    Button { Sfx.play(.tap); onClose(); startDaily() } label: {
                        Label(progress.dailyDone ? "PLAY AGAIN" : "PLAY DAILY", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(size: 18))

                    Divider().overlay(UI.stroke)
                    Text("FRIEND CHALLENGE").font(UI.body(10, .heavy)).tracking(1.5).foregroundStyle(UI.sub)
                    HStack {
                        TextField("", text: $code, prompt: Text("Enter code  SS-XXXX-XX").foregroundColor(.white.opacity(0.35)))
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .font(UI.body(15, .bold)).foregroundStyle(.white)
                            .padding(10).background(UI.glass, in: RoundedRectangle(cornerRadius: 12))
                        Button("Go") { if session.submit(code: code) { onClose() } }
                            .buttonStyle(GlassButtonStyle()).disabled(code.count < 6)
                    }
                    if session.invalidCode { Text("That code doesn't look right.").font(UI.body(11)).foregroundStyle(UI.pink) }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    Text("LOGIN STREAK").font(UI.body(10, .heavy)).tracking(1.5).foregroundStyle(UI.sub)
                    HStack(spacing: 5) {
                        ForEach(1...7, id: \.self) { d in
                            let reached = (progress.d.streak - 1) % 7 + 1 >= d
                            Text("\(d)").font(UI.title(12)).foregroundStyle(reached ? .black : .white.opacity(0.5))
                                .frame(width: 26, height: 26)
                                .background(reached ? UI.gold : Color.white.opacity(0.1), in: Circle())
                        }
                    }
                    Text("\(progress.d.streak) day streak").font(UI.title(16)).foregroundStyle(.white)
                    Button { progress.claimLogin(); Sfx.play(.reward) } label: {
                        Text(progress.loginRewardAvailable ? "CLAIM +\(progress.loginReward) ◆" : "COME BACK TOMORROW")
                    }
                    .buttonStyle(PrimaryButtonStyle(colors: [UI.gold, Color(hex: 0xFF9F1C)], size: 14))
                    .foregroundStyle(.black)
                    .disabled(!progress.loginRewardAvailable)
                    .opacity(progress.loginRewardAvailable ? 1 : 0.5)
                }
                .padding(14).frame(width: 250)
                .background(UI.glass, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(UI.stroke))
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
        }
    }
}

// MARK: - Settings

struct SettingsPanel: View {
    let onClose: () -> Void
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var store: Store
    @Environment(\.openURL) private var openURL

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    var body: some View {
        Panel(title: "Settings", onClose: onClose) {
            ScrollView {
                VStack(spacing: 8) {
                    toggle("Sound effects", "speaker.wave.2.fill", $progress.d.sound)
                    toggle("Music", "music.note", $progress.d.music)
                    toggle("Haptics", "iphone.radiowaves.left.and.right", $progress.d.haptics)
                    toggle("Reduce screen effects", "sparkles", $progress.d.reduceFX)
                    row("Restore Purchases", "arrow.clockwise") { Task { await store.restore() } }
                    row("Privacy Policy", "hand.raised.fill") { open("https://marco-p-keller.github.io/ShadowSwitch/privacy.html") }
                    row("Terms of Use (EULA)", "doc.text.fill") { open("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") }
                    row("Support", "questionmark.circle.fill") { open("https://marco-p-keller.github.io/ShadowSwitch/support.html") }
                    if let m = store.message { Text(m).font(UI.body(12)).foregroundStyle(UI.gold) }
                    Text("Shadow Switch \(version)").font(UI.body(11)).foregroundStyle(UI.sub).padding(.top, 6)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .onChange(of: progress.d.sound) { _, v in Sfx.enabled = v }
        .onChange(of: progress.d.music) { _, v in Sfx.musicEnabled = v; Sfx.updateMusic(playing: v) }
        .onChange(of: progress.d.haptics) { _, v in Sfx.hapticsEnabled = v }
    }

    func open(_ s: String) { if let u = URL(string: s) { openURL(u) } }

    func toggle(_ title: String, _ icon: String, _ b: Binding<Bool>) -> some View {
        Toggle(isOn: b) {
            Label(title, systemImage: icon).font(UI.body(15, .bold)).foregroundStyle(.white)
        }
        .tint(UI.violet)
        .padding(12).background(UI.glass, in: RoundedRectangle(cornerRadius: 14))
    }

    func row(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon).font(UI.body(15, .bold)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(UI.sub)
            }
            .padding(12).background(UI.glass, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
