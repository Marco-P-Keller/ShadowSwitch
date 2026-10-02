import SwiftUI

enum UI {
    static let ink = Color(hex: 0x0B0720)
    static let violet = Color(hex: 0x8B5CF6)
    static let cyan = Color(hex: 0x22D3EE)
    static let pink = Color(hex: 0xFF2BD6)
    static let gold = Color(hex: 0xFFD54F)
    static let glass = Color.white.opacity(0.09)
    static let stroke = Color.white.opacity(0.16)
    static let sub = Color.white.opacity(0.62)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .rounded) }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { .system(size: size, weight: weight, design: .rounded) }
}

struct PrimaryButtonStyle: ButtonStyle {
    var colors: [Color] = [UI.pink, UI.violet]
    var size: CGFloat = 20
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UI.title(size))
            .foregroundStyle(.white)
            .padding(.horizontal, size * 1.4)
            .padding(.vertical, size * 0.6)
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: colors[0].opacity(0.55), radius: 14, y: 4)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var size: CGFloat = 15
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UI.title(size))
            .foregroundStyle(.white)
            .padding(.horizontal, size * 1.1)
            .padding(.vertical, size * 0.6)
            .background(.ultraThinMaterial.opacity(0.7), in: Capsule())
            .background(UI.glass, in: Capsule())
            .overlay(Capsule().strokeBorder(UI.stroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct Pill: View {
    let icon: String
    let text: String
    var tint: Color = UI.gold
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 13, weight: .bold))
            Text(text).font(UI.title(14)).foregroundStyle(.white).monospacedDigit()
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .background(.black.opacity(0.35), in: Capsule())
        .overlay(Capsule().strokeBorder(UI.stroke, lineWidth: 1))
    }
}

struct Panel<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let onClose: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { onClose() }
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased()).font(UI.title(22)).foregroundStyle(.white).tracking(1)
                        if let subtitle { Text(subtitle).font(UI.body(12)).foregroundStyle(UI.sub) }
                    }
                    Spacer()
                    Button { Sfx.play(.tap); onClose() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white).frame(width: 32, height: 32)
                            .background(UI.glass, in: Circle()).overlay(Circle().strokeBorder(UI.stroke))
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 10)
                content
            }
            .background(
                LinearGradient(colors: [Color(hex: 0x1A1038), Color(hex: 0x0E0824)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(UI.stroke, lineWidth: 1))
            .shadow(color: UI.violet.opacity(0.35), radius: 30)
            .padding(.horizontal, 28).padding(.vertical, 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

struct GradientTitle: View {
    let text: String
    let size: CGFloat
    var colors: [Color] = [.white, Color(hex: 0xC9B8FF)]
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(size * 0.02)
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
    }
}
