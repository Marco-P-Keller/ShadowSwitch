#!/usr/bin/env python3
"""Synthesises all Shadow Switch sound effects + the music loop (stdlib only)."""
import math, random, struct, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "ShadowSwitch", "Resources", "Sounds")
os.makedirs(OUT, exist_ok=True)

def write(name, samples, vol=0.9):
    peak = max(1e-9, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * vol)) * 32767)) for s in samples))

def env(i, n, a=0.01, r=0.3):
    t = i / n
    return min(1, t / a) * (1 - t) ** (1 + r * 3)

def tone(freq0, freq1, dur, wave_fn="sine", a=0.01):
    n = int(SR * dur); out = []; ph = 0
    for i in range(n):
        f = freq0 + (freq1 - freq0) * (i / n)
        ph += 2 * math.pi * f / SR
        if wave_fn == "sine": s = math.sin(ph)
        elif wave_fn == "square": s = 1 if math.sin(ph) > 0 else -1; s *= 0.5
        elif wave_fn == "saw": s = ((ph / (2 * math.pi)) % 1) * 2 - 1; s *= 0.6
        else: s = math.sin(ph) + 0.4 * math.sin(2 * ph)
        out.append(s * env(i, n, a))
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0 for t in tracks) for i in range(n)]

def seq(*parts):
    out = []
    for p in parts: out += p
    return out

def noise(dur, lp=0.2):
    n = int(SR * dur); y = 0; out = []
    for i in range(n):
        y += (random.uniform(-1, 1) - y) * lp
        out.append(y * env(i, n, 0.002, 0.5))
    return out

# SFX
write("sw_real", mix(tone(700, 1100, 0.11, "soft"), tone(350, 550, 0.11, "sine")), 0.8)
write("sw_shadow", mix(tone(500, 250, 0.14, "soft"), tone(1000, 480, 0.14, "sine")), 0.8)
write("coin", seq(tone(1175, 1175, 0.05, "square", 0.002), tone(1568, 1568, 0.12, "square", 0.002)), 0.45)
write("close", seq(tone(880, 1320, 0.06, "soft"), tone(1320, 1760, 0.14, "soft")), 0.8)
write("death", mix(noise(0.5, 0.08), tone(300, 40, 0.5, "saw")), 0.95)
write("event", seq(tone(220, 440, 0.15, "saw"), tone(330, 660, 0.15, "saw"), tone(440, 880, 0.3, "soft")), 0.8)
write("reward", seq(tone(659, 659, 0.08, "soft"), tone(784, 784, 0.08, "soft"), tone(1047, 1047, 0.08, "soft"), tone(1319, 1319, 0.3, "soft")), 0.8)
write("tap", tone(900, 700, 0.05, "soft"), 0.5)
write("best", seq(*[tone(f, f, 0.11, "soft") for f in (523, 659, 784, 1047, 1319, 1568)], tone(2093, 2093, 0.4, "soft")), 0.8)

# Music loop: 8 bars @ 112 BPM, A minor — Am | F | C | G
bpm = 112; beat = 60 / bpm; bars = 8; total = int(SR * beat * 4 * bars)
buf = [0.0] * total
def add(start_s, samples, gain):
    s0 = int(start_s * SR)
    for i, v in enumerate(samples):
        if s0 + i < total: buf[s0 + i] += v * gain
def note(m): return 440 * 2 ** ((m - 69) / 12)
chords = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [48, 52, 55]), (55, [55, 59, 62])]
for bar in range(bars):
    root, tri = chords[bar % 4]
    t0 = bar * beat * 4
    for b in range(8):                      # driving bass 8ths
        add(t0 + b * beat / 2, tone(note(root - 12), note(root - 12), beat / 2 * 0.9, "saw", 0.005), 0.22)
    for b in range(16):                     # arp 16ths
        m = tri[[0, 1, 2, 1][b % 4]] + (12 if b % 8 >= 4 else 0)
        add(t0 + b * beat / 4, tone(note(m + 12), note(m + 12), beat / 4 * 0.8, "square", 0.003), 0.07)
    for b in range(4):                      # kick
        add(t0 + b * beat, tone(120, 45, 0.18, "sine", 0.002), 0.5)
    for b in range(8):                      # hat
        if b % 2 == 1: add(t0 + b * beat / 2, noise(0.04, 0.6), 0.08)
    for b in (1, 3):                        # snare
        add(t0 + b * beat, noise(0.12, 0.35), 0.18)
write("music", buf, 0.7)
print("sounds written to", os.path.abspath(OUT))
