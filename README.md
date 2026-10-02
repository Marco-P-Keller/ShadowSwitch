# Shadow Switch

Hyper-casual one-tap runner for iOS. Flip between the **Real World** and the **Shadow World** — solid obstacles only hurt in their own world. The longer you survive, the weirder it gets.

- SwiftUI + Canvas, deterministic fixed-step engine (seeded runs → shareable friend challenges)
- 8 absurd run events, 7 daily modifiers, Shadow Pass, skins & worlds, StoreKit 2
- No ads, no tracking, no third-party SDKs
- Procedural graphics and synthesized audio — no external assets

## Build
```
brew install xcodegen
xcodegen generate
open ShadowSwitch.xcodeproj
```
`tools/` contains the generators for sounds, icon and store screenshots. `docs/` is the GitHub Pages site (privacy policy, support).
