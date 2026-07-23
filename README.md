# KI BLOBS — Aerial Brawl

A playable prototype of a **2D aerial fighting game** in the *Lemming Ball Z* / Dragon-Ball-Z-arena-fighter tradition: two round "blobs" fly freely around an arena, trade melee blows up close, **charge ki**, fire **energy blasts**, and **block** — first to drain the other's health wins.

It's an **original** take (original name, art, and code) so it stays clear of the *Lemmings* and *Dragon Ball* trademarks. Everything is drawn procedurally on an HTML5 canvas — no external assets — so the whole game is a single self-contained file.

## Play

Open `index.html` in any modern browser (desktop or mobile). No build step, no dependencies.

- **Desktop:** just double-click the file, or serve the folder: `python3 -m http.server` then visit `http://localhost:8000`.
- **Phone:** open the same URL on your phone's browser — on-screen touch controls appear automatically.

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Fly / move | WASD or Arrow keys | Left stick |
| Punch (melee) | `J` | PUNCH |
| Ki blast (costs ki) | `K` | BLAST |
| Charge ki (hold) | `L` | CHARGE |
| Block (hold) | `Shift` | BLOCK |
| Start / rematch | `Space` | any button |

**Loop:** you regain a little ki over time, but **hold CHARGE** to refill it fast (you're nearly stationary and vulnerable while doing so). Spend ki on blasts; close the distance for free melee damage; block to cut incoming damage to ~25% — but only when you're facing the attack.

## What's implemented

- Free 8-direction flight with acceleration/friction and arena bounds
- Melee with knockback + a short punch animation
- Ki system: cost, fast charge, passive regen, ki bar
- Ki-blast projectiles with trails, wall collisions, and hit detection
- Blocking (directional damage reduction) with a shield visual
- A finite-state-machine **AI rival** (approach / blast / melee / charge / dodge / block)
- Health + ki HUD, round-start intro, K.O. / win-lose screen, instant rematch
- Juice: hit sparks, screen shake, charging aura + rings, procedural WebAudio SFX
- Dusk arena background (gradient sky, sun, parallax-style mountains, stars)

## Roadmap → native Android

This web build proves the mechanics and *feel*. Two paths to a real Android app:

1. **Fastest APK (reuse this code):** wrap the web build with **Capacitor** or ship it as a **Trusted Web Activity (TWA)** via Bubblewrap. The game already has touch controls and a mobile viewport, so it runs as-is inside a WebView.
2. **Native game engine (recommended for a polished title):** port the mechanics to **Godot 4** — free, excellent 2D, one-click Android/APK export. The systems here (fighter state, ki, projectiles, AI FSM) map cleanly onto Godot nodes and GDScript.

### Likely next features
- Sprite/animation art pass (idle, fly, punch, charge, hit, KO)
- Energy **beam** attack + beam-struggle mechanic
- Transformations (spend ki for a temporary power/aura boost)
- Dash / teleport (double-tap or dedicated button)
- Character roster + simple move variations
- Round system (best of 3), pause menu, settings, haptics
- Difficulty levels for the AI; optional local 2-player

## Files

- `index.html` — the entire game (canvas + game loop + input + AI + audio)
- `README.md` — this file
