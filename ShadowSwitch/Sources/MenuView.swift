import SwiftUI

struct MenuView: View {
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var session: GameSession
    @EnvironmentObject var store: Store
    @Binding var panel: ActivePanel?

    private var starterVisible: Bool {
        !progress.d.starterBought && progress.d.totalRuns >= 2
    }
    private var starterRemaining: String? {
        let end = progress.d.installDate.addingTimeInterval(72 * 3600)
        let left = end.timeIntervalSinceNow
        guard left > 0 else { return nil }
        let h = Int(left) / 3600, m = (Int(left) % 3600) / 60
        return "\(h)h \(m)m left"
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.78), .black.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                .ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: 28) {
                    hero
                    Spacer(minLength: 0)
                    VStack(spacing: 10) {
                        dailyCard
                        if starterVisible { starterCard }
                        statsCard
                    }
                    .frame(width: 270)
                }
                Spacer(minLength: 0)
                bottomBar
            }
            .padding(.horizontal, 22).padding(.vertical, 10)
        }
    }

    // MARK: Pieces

    var topBar: some View {
        HStack(spacing: 8) {
            Button { panel = .shards } label: { Pill(icon: "diamond.fill", text: "\(progress.d.shards)") }
                .accessibilityLabel("Shards \(progress.d.shards). Open shop")
            Pill(icon: "heart.fill", text: "\(progress.d.revives)", tint: UI.pink)
                .accessibilityLabel("Second chances \(progress.d.revives)")
            Spacer()
            Pill(icon: "flame.fill", text: "\(progress.d.streak) day streak", tint: Color(hex: 0xFF6B1A))
            Button { Sfx.play(.tap); panel = .settings } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(.black.opacity(0.35), in: Circle())
                    .overlay(Circle().strokeBorder(UI.stroke))
            }
            .accessibilityLabel("Settings")
        }
    }

    var hero: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TWO WORLDS · ONE TAP").font(UI.body(12, .heavy)).tracking(3).foregroundStyle(UI.cyan)
            GradientTitle(text: "SHADOW", size: 58)
            GradientTitle(text: "SWITCH", size: 58, colors: [UI.pink, UI.violet]).padding(.top, -14)
            Text("The longer you survive, the weirder it gets.").font(UI.body(13)).foregroundStyle(UI.sub).padding(.bottom, 10)
            PlayButton { session.startRun(.standard) }
        }
    }

    var dailyCard: some View {
        let m = progress.dailyModifier
        return Button { Sfx.play(.tap); panel = .daily } label: {
            HStack(spacing: 12) {
                Image(systemName: m.icon).font(.system(size: 20, weight: .bold)).foregroundStyle(UI.cyan)
                    .frame(width: 42, height: 42).background(UI.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY CHALLENGE").font(UI.body(10, .heavy)).tracking(1.5).foregroundStyle(UI.sub)
                    Text(m.title).font(UI.title(16)).foregroundStyle(.white)
                    Text(progress.dailyDone ? "Completed ✓" : "Reach \(progress.dailyGoal) · +150 ◆")
                        .font(UI.body(12)).foregroundStyle(progress.dailyDone ? UI.cyan : UI.gold)
                }
                Spacer(minLength: 0)
                if progress.loginRewardAvailable || !progress.dailyDone {
                    Circle().fill(UI.pink).frame(width: 10, height: 10)
                }
            }
            .padding(12).background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(UI.stroke))
        }
        .buttonStyle(.plain)
    }

    var starterCard: some View {
        Button { Sfx.play(.tap); panel = .shards } label: {
            HStack(spacing: 10) {
                Image(systemName: "gift.fill").font(.system(size: 20)).foregroundStyle(UI.gold)
                VStack(alignment: .leading, spacing: 1) {
                    Text("STARTER BUNDLE").font(UI.title(13)).foregroundStyle(.white)
                    Text("Neon Fox skin · 1000 ◆ · 3 revives").font(UI.body(11)).foregroundStyle(UI.sub)
                    if let r = starterRemaining { Text(r).font(UI.body(10, .heavy)).foregroundStyle(UI.gold) }
                }
                Spacer(minLength: 0)
                Text(store.price(ProductID.starter)).font(UI.title(14)).foregroundStyle(.black)
                    .padding(.horizontal, 10).padding(.vertical, 5).background(UI.gold, in: Capsule())
            }
            .padding(10)
            .background(LinearGradient(colors: [UI.violet.opacity(0.55), UI.pink.opacity(0.4)], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(UI.gold.opacity(0.6)))
        }
        .buttonStyle(.plain)
    }

    var statsCard: some View {
        HStack {
            stat("BEST", "\(progress.d.best)")
            Divider().frame(height: 24).overlay(UI.stroke)
            stat("RUNS", "\(progress.d.totalRuns)")
            Divider().frame(height: 24).overlay(UI.stroke)
            stat("PASS TIER", "\(progress.passTier)")
        }
        .padding(.vertical, 8).padding(.horizontal, 6)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(UI.stroke))
    }

    func stat(_ k: String, _ v: String) -> some View {
        VStack(spacing: 1) {
            Text(v).font(UI.title(18)).foregroundStyle(.white).monospacedDigit()
            Text(k).font(UI.body(9, .heavy)).tracking(1.2).foregroundStyle(UI.sub)
        }.frame(maxWidth: .infinity)
    }

    var bottomBar: some View {
        HStack(spacing: 10) {
            tile("Daily", "calendar", badge: progress.loginRewardAvailable) { panel = .daily }
            tile("Shadow Pass", "crown.fill", badge: progress.unclaimedCount > 0) { panel = .pass }
            tile("Skins", "person.crop.circle.fill", badge: false) { panel = .skins }
            tile("Worlds", "moon.stars.fill", badge: false) { panel = .worlds }
            tile("Shop", "diamond.fill", badge: false) { panel = .shards }
        }
    }

    func tile(_ title: String, _ icon: String, badge: Bool, _ action: @escaping () -> Void) -> some View {
        Button { Sfx.play(.tap); action() } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                Text(title.uppercased()).font(UI.body(10, .heavy)).tracking(1).foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(UI.stroke))
            .overlay(alignment: .topTrailing) {
                if badge { Circle().fill(UI.pink).frame(width: 10, height: 10).offset(x: -6, y: 6) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct PlayButton: View {
    let action: () -> Void
    @State private var pulse = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("PLAY")
            }
            .frame(minWidth: 150)
        }
        .buttonStyle(PrimaryButtonStyle(size: 26))
        .scaleEffect(pulse ? 1.04 : 1)
        .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true } }
        .accessibilityLabel("Play")
    }
}
