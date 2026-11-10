"""Synthesize the game's UI sound effects and gentle background loop.

No external samples are used; everything is generated with numpy and written
as 16-bit mono WAV files that Godot imports natively.

Usage: python tools/gen_audio.py

WARNING: this overwrites assets/audio/sfx/*.wav and
assets/audio/bgm/morning_loop.wav. Do not run it after replacing those files
with your own recordings. See docs/ASSET_GUIDE.md.
"""
from __future__ import annotations

import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
BGM_DIR = os.path.join(ROOT, "assets", "audio", "bgm")
AMB_DIR = os.path.join(ROOT, "assets", "audio", "ambience")
os.makedirs(SFX_DIR, exist_ok=True)
os.makedirs(BGM_DIR, exist_ok=True)
os.makedirs(AMB_DIR, exist_ok=True)

SR = 44100


def silence(seconds: float) -> np.ndarray:
    return np.zeros(int(SR * seconds), dtype=np.float64)


def attack_decay(n: int, attack: float = 0.006, decay: float = 0.35,
                 release: float = 0.03) -> np.ndarray:
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0.0, 1.0)
    d = np.exp(-t / max(decay, 1e-3))
    rel_n = max(int(SR * release), 1)
    rel = np.ones(n)
    if n > rel_n:
        rel[-rel_n:] = np.linspace(1.0, 0.0, rel_n)
    return a * d * rel


def bell(freq: float, dur: float, gain: float = 1.0) -> np.ndarray:
    t = np.arange(int(SR * dur)) / SR
    wave_ = (np.sin(2 * np.pi * freq * t) * 1.0
             + np.sin(2 * np.pi * freq * 2.0 * t) * 0.32
             + np.sin(2 * np.pi * freq * 3.01 * t) * 0.12)
    return wave_ * attack_decay(len(t), 0.004, 0.42, 0.06) * gain


def marimba(freq: float, dur: float, gain: float = 1.0) -> np.ndarray:
    t = np.arange(int(SR * dur)) / SR
    wave_ = (np.sin(2 * np.pi * freq * t)
             + 0.28 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t / 0.05))
    return wave_ * attack_decay(len(t), 0.002, 0.30, 0.05) * gain


def triangle(freq: float, dur: float, vibrato: float = 0.0) -> np.ndarray:
    t = np.arange(int(SR * dur)) / SR
    f = freq * (1.0 + vibrato * np.sin(2 * np.pi * 5.5 * t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    return (2 / np.pi) * np.arcsin(np.sin(phase))


def mix_into(buf: np.ndarray, sound: np.ndarray, at: float,
             gain: float = 1.0) -> None:
    start = int(SR * at)
    end = min(len(buf), start + len(sound))
    if start >= len(buf):
        return
    buf[start:end] += sound[: end - start] * gain


def save(path: str, data: np.ndarray, peak: float = 0.7) -> None:
    data = np.asarray(data, dtype=np.float64)
    m = np.max(np.abs(data))
    if m > 0:
        data = data / m * peak
    pcm = np.clip(data * 32767.0, -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("wrote", os.path.relpath(path, ROOT), f"{len(data)/SR:.2f}s")


# ------------------------------------------------------------------ effects --
def sfx_pop() -> None:
    t = np.arange(int(SR * 0.12)) / SR
    freq = 520 + 900 * t
    phase = 2 * np.pi * np.cumsum(freq) / SR
    s = np.sin(phase) * attack_decay(len(t), 0.002, 0.045, 0.02)
    save(os.path.join(SFX_DIR, "pop.wav"), s, 0.34)


def sfx_tap() -> None:
    t = np.arange(int(SR * 0.09)) / SR
    s = (np.sin(2 * np.pi * 1180 * t) * 0.7
         + np.sin(2 * np.pi * 1770 * t) * 0.4)
    s *= attack_decay(len(t), 0.001, 0.035, 0.015)
    save(os.path.join(SFX_DIR, "tap.wav"), s, 0.3)


def sfx_success() -> None:
    total = 1.5
    buf = silence(total)
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.50)):
        mix_into(buf, bell(f, 1.1, 1.0), 0.07 * i, 0.8)
    mix_into(buf, bell(1567.98, 0.9, 0.5), 0.30, 0.4)
    mix_into(buf, bell(2093.0, 0.7, 0.3), 0.38, 0.25)
    save(os.path.join(SFX_DIR, "success.wav"), buf, 0.62)


def sfx_error() -> None:
    """Soft 'uh-oh' — never harsh for a 4 year old."""
    total = 0.85
    buf = silence(total)
    first = triangle(392.0, 0.22, 0.01) * attack_decay(int(SR * 0.22), 0.01,
                                                       0.16, 0.04)
    second = triangle(293.66, 0.36, 0.01) * attack_decay(int(SR * 0.36), 0.01,
                                                        0.22, 0.08)
    mix_into(buf, first, 0.02, 0.55)
    mix_into(buf, second, 0.26, 0.55)
    save(os.path.join(SFX_DIR, "error.wav"), buf, 0.42)


def sfx_level_clear() -> None:
    total = 2.2
    buf = silence(total)
    notes = (523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98)
    for i, f in enumerate(notes):
        mix_into(buf, bell(f, 1.6, 0.8), 0.09 * i, 0.55)
    for i, f in enumerate((1046.50, 1318.51, 1567.98, 2093.0)):
        mix_into(buf, marimba(f, 0.9, 0.5), 0.72 + 0.09 * i, 0.32)
    save(os.path.join(SFX_DIR, "level_clear.wav"), buf, 0.6)


def sfx_finish() -> None:
    total = 3.4
    buf = silence(total)
    melody = [(523.25, 0.0), (659.25, 0.16), (783.99, 0.32),
              (1046.50, 0.48), (783.99, 0.70), (1046.50, 0.86),
              (1318.51, 1.02)]
    for f, at in melody:
        mix_into(buf, bell(f, 1.4, 0.8), at, 0.55)
    for f in (523.25, 659.25, 783.99, 1046.50):
        mix_into(buf, bell(f, 2.0, 0.5), 1.25, 0.22)
    save(os.path.join(SFX_DIR, "finish.wav"), buf, 0.6)


def sfx_brush() -> None:
    """Short toothbrush scrub: filtered noise bursts."""
    rng = np.random.default_rng(7)
    total = 0.22
    t = np.arange(int(SR * total)) / SR
    noise = rng.normal(0, 1, len(t))
    # cheap band emphasis around the bristles
    kernel = np.ones(6) / 6.0
    smooth = np.convolve(noise, kernel, mode="same")
    hiss = noise - smooth
    env = np.exp(-t / 0.055) * np.minimum(t / 0.004, 1.0)
    scrub = hiss * env
    buf = scrub * 0.9
    mix_into(buf, np.sin(2 * np.pi * 190 * t) * env * 0.15, 0.0)
    save(os.path.join(SFX_DIR, "brush.wav"), buf, 0.42)


def sfx_splash() -> None:
    rng = np.random.default_rng(11)
    total = 0.8
    t = np.arange(int(SR * total)) / SR
    noise = rng.normal(0, 1, len(t))
    smooth = np.convolve(noise, np.ones(24) / 24.0, mode="same")
    water = smooth * np.exp(-t / 0.22) * np.minimum(t / 0.01, 1.0)
    buf = water * 0.8
    for d in (0.18, 0.32, 0.47):
        idx = int(SR * d)
        blip = np.sin(2 * np.pi * 520 * np.arange(int(SR * 0.08)) / SR)
        mix_into(buf, blip * attack_decay(int(SR * 0.08), 0.002, 0.03), d, 0.12)
    save(os.path.join(SFX_DIR, "splash.wav"), buf, 0.5)


def sfx_snap() -> None:
    t = np.arange(int(SR * 0.12)) / SR
    buf = (np.sin(2 * np.pi * 880 * t) * 0.6
           + np.sin(2 * np.pi * 1760 * t) * 0.35)
    buf *= attack_decay(len(t), 0.001, 0.03, 0.02)
    save(os.path.join(SFX_DIR, "snap.wav"), buf, 0.4)


def sfx_sparkle() -> None:
    total = 1.0
    buf = silence(total)
    for i, f in enumerate((1567.98, 2093.0, 2637.02, 3135.96)):
        mix_into(buf, bell(f, 0.7, 0.5), 0.07 * i, 0.35)
    save(os.path.join(SFX_DIR, "sparkle.wav"), buf, 0.42)


def ambience_bedroom() -> None:
    """Soft morning room tone with distant birds, loopable."""
    rng = np.random.default_rng(3)
    total = 12.0
    t = np.arange(int(SR * total)) / SR
    bed = silence(total)
    # warm pad
    for f in (130.81, 196.0, 261.63):
        bed += np.sin(2 * np.pi * f * t) * 0.035
    # air
    air = rng.normal(0, 1, len(t))
    air = np.convolve(air, np.ones(120) / 120.0, mode="same")
    bed += air * 0.10
    # birds
    for at in (0.6, 2.1, 3.6, 6.4, 8.2, 10.1):
        dur = 0.13
        bt = np.arange(int(SR * dur)) / SR
        f0 = 2100 + rng.integers(-200, 400)
        f1 = f0 + 700
        phase = 2 * np.pi * np.cumsum(f0 + (f1 - f0) * bt / dur) / SR
        chirp = np.sin(phase) * attack_decay(len(bt), 0.005, 0.06, 0.02)
        mix_into(bed, chirp, at, 0.10)
        mix_into(bed, chirp, at + 0.16, 0.07)
    # gentle low chord swells
    for at in (2.0, 7.0):
        dur = 2.4
        st = np.arange(int(SR * dur)) / SR
        swell = (np.sin(2 * np.pi * 329.63 * st)
                 + np.sin(2 * np.pi * 392.0 * st)) * 0.03
        swell *= np.minimum(st / 0.6, 1.0) * np.minimum((dur - st) / 0.8, 1.0)
        mix_into(bed, swell, at, 0.5)
    fade = int(SR * 0.05)
    bed[:fade] *= np.linspace(0, 1, fade)
    bed[-fade:] *= np.linspace(1, 0, fade)
    save(os.path.join(AMB_DIR, "bedroom.wav"), bed, 0.30)


def ambience_bathroom() -> None:
    """Tiled room tone with water drips, loopable."""
    rng = np.random.default_rng(5)
    total = 10.0
    t = np.arange(int(SR * total)) / SR
    buf = silence(total)
    air = rng.normal(0, 1, len(t))
    air = np.convolve(air, np.ones(220) / 220.0, mode="same")
    buf += air * 0.09
    for f in (174.61, 261.63):
        buf += np.sin(2 * np.pi * f * t) * 0.012
    for at in (0.8, 2.6, 4.4, 6.1, 8.3):
        dur = 0.16
        dt = np.arange(int(SR * dur)) / SR
        freq = 1400 + rng.integers(-200, 200)
        drop = np.sin(2 * np.pi * freq * dt) * attack_decay(len(dt), 0.002, 0.05, 0.03)
        mix_into(buf, drop, at, 0.16)
        echo = np.sin(2 * np.pi * freq * 0.98 * dt) * attack_decay(len(dt), 0.002, 0.12, 0.06)
        mix_into(buf, echo, at + 0.22, 0.06)
    fade = int(SR * 0.05)
    buf[:fade] *= np.linspace(0, 1, fade)
    buf[-fade:] *= np.linspace(1, 0, fade)
    save(os.path.join(AMB_DIR, "bathroom.wav"), buf, 0.28)


# ---------------------------------------------------------------------- bgm --
def bgm_morning_loop() -> None:
    bpm = 100.0
    beat = 60.0 / bpm
    bar = beat * 4
    bars = 8
    total = bar * bars
    buf = silence(total)

    # I - vi - IV - V, twice
    chords = [
        ([261.63, 329.63, 392.00], 130.81),
        ([220.00, 261.63, 329.63], 110.00),
        ([174.61, 220.00, 261.63], 87.31),
        ([196.00, 246.94, 293.66], 98.00),
    ]
    pattern = [0, 1, 2, 1, 0, 2, 1, 2]  # eighth-note arpeggio

    for b in range(bars):
        chord, bass = chords[b % 4]
        bar_at = b * bar
        # soft pad
        pad_dur = bar
        t = np.arange(int(SR * pad_dur)) / SR
        pad = np.zeros_like(t)
        for f in chord:
            pad += np.sin(2 * np.pi * f * t) * 0.10
        pad *= np.minimum(t / 0.4, 1.0) * np.minimum((pad_dur - t) / 0.5, 1.0)
        mix_into(buf, pad, bar_at, 0.30)
        # bass on beats 1 and 3
        for at in (0.0, 2 * beat):
            mix_into(buf, marimba(bass, 0.7, 1.0), bar_at + at, 0.32)
        # marimba arpeggio
        for i, idx in enumerate(pattern):
            f = chord[idx] * 2.0
            mix_into(buf, marimba(f, 0.5, 1.0), bar_at + i * beat * 0.5,
                     0.20 if i % 2 else 0.26)
        # sparkle every other bar
        if b % 2 == 1:
            mix_into(buf, bell(chord[2] * 4.0, 1.2, 0.18), bar_at + 2.5 * beat)

    # tiny fade at both ends so the loop point is click-free
    fade = int(SR * 0.02)
    buf[:fade] *= np.linspace(0.0, 1.0, fade)
    buf[-fade:] *= np.linspace(1.0, 0.0, fade)
    save(os.path.join(BGM_DIR, "morning_loop.wav"), buf, 0.32)


if __name__ == "__main__":
    sfx_pop()
    sfx_tap()
    sfx_success()
    sfx_error()
    sfx_level_clear()
    sfx_finish()
    sfx_brush()
    sfx_splash()
    sfx_snap()
    sfx_sparkle()
    bgm_morning_loop()
    ambience_bedroom()
    ambience_bathroom()
