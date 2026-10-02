import SwiftUI
import StoreKit

@main
struct ShadowSwitchApp: App {
    @StateObject private var progress: PlayerData
    @StateObject private var store: Store
    @StateObject private var session: GameSession

    init() {
        let p = PlayerData()
        _progress = StateObject(wrappedValue: p)
        _store = StateObject(wrappedValue: Store(progress: p))
        _session = StateObject(wrappedValue: GameSession(progress: p))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environmentObject(store)
                .environmentObject(session)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var progress: PlayerData
    @EnvironmentObject var session: GameSession
    @EnvironmentObject var store: Store
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @State private var panel: ActivePanel?
    @State private var touching = false

    var body: some View {
        ZStack {
            GameCanvasView(session: session)

            // touch layer
            if session.screen == .playing {
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !touching { touching = true; session.tap() } }
                        .onEnded { _ in touching = false })
                HUDView(session: session)
                    .transition(.opacity)
            }

            switch session.screen {
            case .menu:
                MenuView(panel: $panel).transition(.opacity)
            case .paused:
                PauseView(session: session)
            case .dead:
                DeathView(session: session).transition(.opacity)
            case .playing:
                EmptyView()
            }

            if let p = panel { panelView(p).zIndex(10) }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: session.screen)
        .animation(.easeInOut(duration: 0.2), value: panel?.id)
        .onAppear {
            Sfx.enabled = progress.d.sound; Sfx.musicEnabled = progress.d.music; Sfx.hapticsEnabled = progress.d.haptics
            Sfx.prepare(); Sfx.updateMusic(playing: true)
            session.cardRenderer = { r in renderCard(r) }
            Demo.apply(session: session, progress: progress, setPanel: { panel = $0 })
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause(); Sfx.updateMusic(playing: false) }
            else { Sfx.updateMusic(playing: true); progress.refreshStreak() }
        }
        .onChange(of: session.askReview) { _, v in
            if v { session.askReview = false; DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { requestReview() } }
        }
        .onOpenURL { session.handle(url: $0) }
        .alert("Challenge accepted", isPresented: Binding(get: { session.pendingChallenge != nil }, set: { if !$0 { session.pendingChallenge = nil } })) {
            Button("Let's go") {
                if let c = session.pendingChallenge { session.pendingChallenge = nil; session.startRun(.challenge(c.seed, c.score)) }
            }
            Button("Not now", role: .cancel) { session.pendingChallenge = nil }
        } message: {
            Text("Beat \(session.pendingChallenge?.score ?? 0) points on the exact same run to win the Rival skin.")
        }
    }

    @ViewBuilder func panelView(_ p: ActivePanel) -> some View {
        switch p {
        case .daily: DailyPanel(onClose: { panel = nil }, startDaily: { session.startRun(.daily) })
        case .pass: PassPanel(onClose: { panel = nil })
        case .skins: ShopPanel(tab: .skins, onClose: { panel = nil }, openPass: { panel = .pass })
        case .worlds: ShopPanel(tab: .worlds, onClose: { panel = nil }, openPass: { panel = .pass })
        case .shards: ShopPanel(tab: .shards, onClose: { panel = nil }, openPass: { panel = .pass })
        case .settings: SettingsPanel(onClose: { panel = nil })
        }
    }

    @MainActor func renderCard(_ r: RunResult) -> UIImage? {
        let view = ShareCard(result: r, skin: progress.skin)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - Share card (the "Fail of the Day" image)

struct ShareCard: View {
    let result: RunResult
    let skin: Skin

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                LinearGradient(colors: [Color(hex: 0xFFB36B), Color(hex: 0xFFE3C2)], startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [Color(hex: 0x1A0838), Color(hex: 0x4B1C8C)], startPoint: .top, endPoint: .bottom)
            }
            VStack(spacing: 6) {
                Text("SHADOW SWITCH").font(.system(size: 15, weight: .black, design: .rounded)).tracking(4).foregroundStyle(.white)
                    .shadow(radius: 4)
                Spacer(minLength: 0)
                HStack(spacing: 24) {
                    StaticSkinFigure(skin: skin, world: .real).frame(width: 70, height: 80)
                    StaticSkinFigure(skin: skin, world: .shadow).frame(width: 70, height: 80)
                }
                Text("\(result.score)").font(.system(size: 78, weight: .black, design: .rounded)).foregroundStyle(.white).shadow(radius: 6)
                Text("“\(result.cause)”").font(.system(size: 15, weight: .bold, design: .rounded)).italic()
                    .multilineTextAlignment(.center).foregroundStyle(.white).padding(.horizontal, 22)
                Spacer(minLength: 0)
                VStack(spacing: 3) {
                    Text("CAN YOU BEAT ME?").font(.system(size: 12, weight: .black, design: .rounded)).tracking(2).foregroundStyle(.white.opacity(0.85))
                    Text(result.shareCode).font(.system(size: 20, weight: .black, design: .monospaced)).foregroundStyle(Color(hex: 0xFFD54F))
                }
                .padding(.bottom, 4)
            }
            .padding(18)
        }
        .frame(width: 340, height: 440)
    }
}
