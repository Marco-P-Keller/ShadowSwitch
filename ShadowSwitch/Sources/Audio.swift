import AVFoundation
import UIKit

enum SfxKind: String, CaseIterable {
    case switchReal = "sw_real", switchShadow = "sw_shadow", coin, closeCall = "close", death, event, reward, tap, best
}

@MainActor
enum Sfx {
    static var enabled = true
    static var musicEnabled = true
    static var hapticsEnabled = true
    private static var pools: [SfxKind: [AVAudioPlayer]] = [:]
    private static var cursor: [SfxKind: Int] = [:]
    private static var music: AVAudioPlayer?
    private static var ready = false
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        guard !ready else { return }
        ready = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for kind in SfxKind.allCases {
            guard let url = Bundle.main.url(forResource: kind.rawValue, withExtension: "wav") else { continue }
            let n = (kind == .coin || kind == .switchReal || kind == .switchShadow) ? 4 : 2
            pools[kind] = (0..<n).compactMap { _ in
                let p = try? AVAudioPlayer(contentsOf: url)
                p?.prepareToPlay(); p?.volume = kind == .coin ? 0.5 : 0.8
                return p
            }
        }
        if let url = Bundle.main.url(forResource: "music", withExtension: "wav") {
            music = try? AVAudioPlayer(contentsOf: url)
            music?.numberOfLoops = -1
            music?.volume = 0.32
            music?.prepareToPlay()
        }
        light.prepare(); heavy.prepare(); notify.prepare()
    }

    static func play(_ kind: SfxKind) {
        if enabled, let pool = pools[kind], !pool.isEmpty {
            let i = (cursor[kind] ?? 0) % pool.count
            cursor[kind] = i + 1
            pool[i].currentTime = 0
            pool[i].play()
        }
        guard hapticsEnabled else { return }
        switch kind {
        case .switchReal, .switchShadow: light.impactOccurred(intensity: 0.7)
        case .death: heavy.impactOccurred(); notify.notificationOccurred(.error)
        case .closeCall: light.impactOccurred(intensity: 1)
        case .reward, .best: notify.notificationOccurred(.success)
        case .event: heavy.impactOccurred(intensity: 0.5)
        case .tap: light.impactOccurred(intensity: 0.4)
        case .coin: break
        }
    }

    static func updateMusic(playing: Bool) {
        guard let m = music else { return }
        if playing && musicEnabled {
            if !m.isPlaying { m.play() }
        } else if m.isPlaying {
            m.pause()
        }
    }
}
