"""Batch-generate the English voice-over with Microsoft Edge TTS.

Voice: en-US-AnaNeural (a genuine child voice).

One-time setup:
    python -m pip install edge-tts

Usage:
    python tools/vo_pipeline.py            # generate missing clips
    python tools/vo_pipeline.py --force    # regenerate every clip
    python tools/vo_pipeline.py --list     # show the clip table

Clip sources:
  * one clip per word card in data/story.json
  * fixed UI phrases
  * the per-act story lines (intro / action / done / timeout / events),
    each with its own speaking rate
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORY = os.path.join(ROOT, "data", "story.json")
CHECKLIST = os.path.join(ROOT, "data", "checklist.json")
OUT_DIR = os.path.join(ROOT, "assets", "audio", "vo")

VOICE = "en-US-AnaNeural"
RATE = "-8%"
PITCH = "+2Hz"

FIXED = {
    "welcome": ("Good morning! Let's get ready!", "-8%"),
    "success": ("Great job!", "+0%"),
    "try_again": ("Oops! Try again!", "-5%"),
    "finish": ("Hooray! You did it! Good morning!", "+0%"),
    "hint": ("Drag the word card!", "-8%"),
}

ACT_VOICES = [
    # Act 1: wake up
    ("vo_act1_intro.mp3", "Good morning! Wake up, sleepyhead! Rise and shine!", "-15%"),
    ("vo_act1_action.mp3", "Sit up! Wake up!", "-10%"),
    ("vo_act1_done.mp3", "Yay! You are awake!", "+0%"),
    ("vo_timeout_act1.mp3", "Swipe up! Let's get up!", "-10%"),
    # Act 1.5: drink water
    ("vo_act1_5_intro.mp3", "Good morning! Time to drink water! A warm cup for your tummy!", "-15%"),
    ("vo_act1_5_action.mp3", "Pick up the cup! Drink, drink, gulp gulp!", "-5%"),
    ("vo_act1_5_sip.mp3", "Gulp! Gulp! Ahh, Refreshing!", "+0%"),
    ("vo_act1_5_done.mp3", "All done! Good job! You drank water!", "+0%"),
    ("vo_timeout_act1_5.mp3", "Tap the cup! Let's drink water!", "-10%"),
    # Act 2: brush teeth
    ("vo_act2_intro.mp3", "Time to brush your teeth! Let's get the toothpaste!", "-15%"),
    ("vo_act2_brush_l.mp3", "Brush left! Choo-choo!", "+0%"),
    ("vo_act2_brush_r.mp3", "Brush right! Swish-swish!", "+0%"),
    ("vo_act2_brush_all.mp3", "Brush, brush, brush your teeth!", "+0%"),
    ("vo_act2_done.mp3", "Sparkling clean! Good brushing!", "+0%"),
    ("vo_timeout_act2.mp3", "Slide your finger! Brush, brush!", "-10%"),
    # Act 3: wash face
    ("vo_act3_intro.mp3", "Water on! Let's wash your face!", "-15%"),
    ("vo_act3_wash_loop.mp3", "Wash, wash, splash-splash!", "+0%"),
    ("vo_act3_done.mp3", "Fresh and clean! Great wash!", "+0%"),
    ("vo_timeout_act3.mp3", "Rub the towel to wash your face!", "-10%"),
    # Act 4: shirt
    ("vo_act4_intro.mp3", "Look outside, it's sunny! Put on your shirt!", "-15%"),
    ("vo_act4_wrong.mp3", "Oh no! Phew! Too hot! Not the heavy coat! Put on the yellow shirt!", "-5%"),
    ("vo_act4_done.mp3", "Awesome! You put on your shirt!", "+0%"),
    ("vo_timeout_act4.mp3", "Where is the yellow shirt? Tap it!", "-10%"),
    # Act 5: shoes
    ("vo_act5_intro.mp3", "Left shoe, right shoe! Put on your shoes!", "-15%"),
    ("vo_act5_shoe_l.mp3", "Put on the left shoe! Snap!", "+0%"),
    ("vo_act5_shoe_r.mp3", "Put on the right shoe! Snap!", "+0%"),
    ("vo_act5_done.mp3", "One, two, ready to run! Shoes are put on!", "+0%"),
    ("vo_timeout_act5.mp3", "Drag the shoe to your foot!", "-10%"),
    # Act 6: door checklist
    ("vo_act6_checklist.mp3", "Wait! Check the list! Tap the badges!", "-10%"),
    ("vo_act6_badge_0.mp3", "Water? Drink, done!", "+0%"),
    ("vo_act6_badge_1.mp3", "Teeth? Brush, done!", "+0%"),
    ("vo_act6_badge_2.mp3", "Face? Wash, done!", "+0%"),
    ("vo_act6_badge_3.mp3", "Shirt? Put on, done!", "+0%"),
    ("vo_act6_badge_4.mp3", "Shoes? Put on, done!", "+0%"),
    ("vo_act6_finish.mp3", "All done! Give me a high-five! Let's go to school!", "+5%"),
    ("vo_timeout_act6.mp3", "Tap the glowing badge to check!", "-10%"),
]


def load_cards() -> list[dict]:
    with open(STORY, encoding="utf-8") as f:
        levels = json.load(f)
    cards: dict[str, dict] = {}
    for level in levels:
        for card in level.get("cards", []):
            cards.setdefault(card["id"], {
                "id": card["id"],
                "text": card["text"],
                "vo": card.get("vo", ""),
                "rate": RATE,
            })
    return list(cards.values())


def build_jobs() -> list[tuple[str, str, str, str]]:
    """Return (filename, text, label, rate) jobs."""
    jobs: list[tuple[str, str, str, str]] = []
    for card in load_cards():
        vo_path = card["vo"] or f"res://assets/audio/vo/{card['id']}.mp3"
        jobs.append((os.path.basename(vo_path), card["text"],
                     f"card:{card['id']}", card["rate"]))
    for name, (text, rate) in FIXED.items():
        jobs.append((f"{name}.mp3", text, f"ui:{name}", rate))
    for filename, text, rate in ACT_VOICES:
        jobs.append((filename, text, "act", rate))
    return jobs


async def synth(jobs: list[tuple[str, str, str, str]], force: bool) -> int:
    try:
        import edge_tts  # noqa: WPS433
    except ImportError:
        print("edge-tts is not installed. Run: python -m pip install edge-tts",
              file=sys.stderr)
        return 2

    os.makedirs(OUT_DIR, exist_ok=True)
    made = 0
    for filename, text, label, rate in jobs:
        path = os.path.join(OUT_DIR, filename)
        if os.path.exists(path) and os.path.getsize(path) > 1024 and not force:
            print("skip ", filename)
            continue
        # Write to a temp file first so a failed request never leaves a
        # truncated clip in the repository.
        fd, tmp = tempfile.mkstemp(suffix=".mp3", dir=OUT_DIR)
        os.close(fd)
        try:
            communicate = edge_tts.Communicate(text, VOICE, rate=rate,
                                               pitch=PITCH)
            await communicate.save(tmp)
            if os.path.getsize(tmp) < 1024:
                raise RuntimeError("empty audio returned")
            os.replace(tmp, path)
            print("wrote", filename, "<-", label, f"({rate})", f"{text!r}")
            made += 1
        except Exception as exc:  # noqa: BLE001 - CLI should continue
            print(f"FAILED {filename}: {exc}", file=sys.stderr)
            if os.path.exists(tmp):
                os.remove(tmp)
    print(f"done: {made} clip(s) generated")
    return 0 if made else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    jobs = build_jobs()
    if args.list:
        for filename, text, label, rate in jobs:
            print(f"{filename:26s} {label:16s} {rate:5s} {text}")
        return 0
    return asyncio.run(synth(jobs, args.force))


if __name__ == "__main__":
    raise SystemExit(main())
