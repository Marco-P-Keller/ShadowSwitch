# -*- coding: utf-8 -*-
EN = dict(
 name="Shadow Switch: Tap Runner",
 subtitle="Endless Dodge & Reflex Game",
 promo="Season 1 is live! Flip between two worlds with one tap, survive lava floors and backwards crowds, and challenge friends with a code. No ads. Ever.",
 keywords="arcade,casual,reflex,endless,dodge,neon,challenge,friends,skins,addictive,offline,fast,ghost",
 description="""Two worlds. One tap. Zero mercy.

SHADOW SWITCH is the one-tap runner where you flip between the Real World and the Shadow World in a split second. Obstacles only hurt in their own world, so time your switch, dodge at the last moment and chain Close Calls for huge scores.

The longer you survive, the weirder it gets:
• Everyone suddenly walks backwards
• The shadows start talking (and judging you)
• The Shadow floor turns into LAVA
• Gravity quits mid-run
• The whole world flips into a mirror
• Shadow Disco, Thick Fog, Speed Surge and more

EASY TO LEARN, IMPOSSIBLE TO PUT DOWN
Tap anywhere to switch worlds. That's it. A 3-second tutorial and you're running. Every run is different, every death is funny, and "just one more try" turns into an hour.

DAILY CHALLENGE
A brand-new twist every single day: Switch Budget, Ghost Town, Turbo Shadow, Mirror World, Thick Fog, Upside Down, Shard Rain. Beat the daily goal for bonus rewards and keep your streak alive.

CHALLENGE YOUR FRIENDS
Every run has a code. Send it to a friend and they play your exact run, same obstacles, same events. Beat their score to unlock the exclusive Rival skin. Share your weirdest death as a ready-made card for TikTok, Instagram and Messages.

COLLECT & CUSTOMIZE
• 13 shadow skins with unique accessories and trails
• 4 animated worlds: Neon City, Candy Dream, Cyber Grid, Haunted Night
• Earn shards by playing, unlock everything for free

SHADOW PASS
Level up through 20 tiers of rewards with every run. Free track for everyone, premium track for skins, worlds and bonus shards.

FAIR. NO ADS. NO PAY-TO-WIN.
Shadow Switch has no ads, no timers and no energy system. Purchases are cosmetic only. Play offline, anywhere.

Download now and find out how long you can survive between two worlds.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://marco-p-keller.github.io/ShadowSwitch/privacy.html""",
)
DE = dict(
 name="Shadow Switch: Tap Runner",
 subtitle="Endlos Reaktion & Ausweichen",
 promo="Saison 1 ist da! Wechsle mit einem Tipp zwischen zwei Welten, überlebe Lava-Böden und rückwärts laufende Menschen und fordere Freunde per Code heraus. Keine Werbung.",
 keywords="arcade,spiel,reaktion,endlos,ausweichen,neon,freunde,skins,süchtig,offline,schnell,geist,lustig",
 description="""Zwei Welten. Ein Tipp. Keine Gnade.

SHADOW SWITCH ist der One-Tap-Runner, in dem du in Sekundenbruchteilen zwischen der Echten Welt und der Schattenwelt wechselst. Hindernisse tun nur in ihrer eigenen Welt weh – timing ist alles. Weiche im letzten Moment aus und sammle Close-Call-Ketten für riesige Scores.

Je länger du überlebst, desto verrückter wird es:
• Plötzlich laufen alle rückwärts
• Die Schatten fangen an zu reden (und urteilen über dich)
• Der Schattenboden wird zu LAVA
• Die Schwerkraft macht Pause
• Die ganze Welt spiegelt sich
• Schatten-Disco, dichter Nebel, Speed Surge und mehr

LEICHT ZU LERNEN, SCHWER ZU STOPPEN
Tippe irgendwo, um die Welt zu wechseln. Mehr nicht. 3 Sekunden Tutorial und es geht los. Jeder Run ist anders, jeder Tod ist witzig – und aus „nur noch einmal“ wird eine Stunde.

TÄGLICHE CHALLENGE
Jeden Tag ein neuer Twist: Switch-Budget, Geisterstadt, Turbo, Spiegelwelt, dichter Nebel, Kopfüber, Scherbenregen. Erreiche das Tagesziel für Belohnungen und halte deine Serie am Leben.

FORDERE FREUNDE HERAUS
Jeder Run hat einen Code. Schick ihn einem Freund und er spielt exakt deinen Run – gleiche Hindernisse, gleiche Events. Schlage seinen Score und schalte den exklusiven Rival-Skin frei. Teile deinen absurdesten Tod als fertige Karte auf TikTok, Instagram und in Nachrichten.

SAMMELN & ANPASSEN
• 13 Schatten-Skins mit Accessoires und Spuren
• 4 animierte Welten: Neon City, Candy Dream, Cyber Grid, Haunted Night
• Scherben beim Spielen verdienen und alles kostenlos freischalten

SHADOW PASS
Steige mit jedem Run durch 20 Belohnungsstufen. Kostenlose Spur für alle, Premium-Spur mit Skins, Welten und Bonus-Scherben.

FAIR. KEINE WERBUNG. KEIN PAY-TO-WIN.
Keine Werbung, keine Timer, kein Energiesystem. Käufe sind rein kosmetisch. Spiele offline, überall.

Lade jetzt herunter und finde heraus, wie lange du zwischen zwei Welten überlebst.

Nutzungsbedingungen: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutz: https://marco-p-keller.github.io/ShadowSwitch/privacy.html""",
)
REVIEW_NOTES = """Shadow Switch is a one-tap arcade runner. No account or login is required.

How to play: tap anywhere on screen to switch between the Real World and the Shadow World. Solid obstacles only hurt in their own world.

In-App Purchases (all cosmetic / convenience, no pay-to-win):
- Shadow Pass Premium (non-consumable): unlocks the premium reward track of the season pass.
- Starter Bundle (non-consumable): Neon Fox skin, 1000 shards, 3 second chances.
- 600 Shards / 4000 Shards (consumable): soft currency for cosmetics.
They can be found on the home screen via the SHOP tile or the SHADOW PASS tile. "Restore Purchases" is in Settings (gear icon, top right) and in the Shop.

The app contains no ads, no tracking, no user accounts and no third-party SDKs. Friend challenges use a text code that the user shares via the iOS share sheet."""
if __name__ == "__main__":
    for n, d in (("EN", EN), ("DE", DE)):
        print(n, "name", len(d["name"]), "subtitle", len(d["subtitle"]), "promo", len(d["promo"]), "kw", len(d["keywords"]), "desc", len(d["description"]))
