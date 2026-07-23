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
| **Beam** (hold to charge, release to fire) | `I` | BEAM |
| Block (hold) | `Shift` | BLOCK |
| Start / rematch | `Space` | any button |

**Loop:** you regain a little ki over time, but **hold CHARGE** to refill it fast (you're nearly stationary and vulnerable while doing so). Keep charging past a full ki bar and you build **overcharge → SURGE**, a temporary damage boost that supersizes your next blast/beam. Spend ki on blasts and beams; close the distance for free melee damage; block to cut incoming damage to ~25% — but only when facing the attack. Beams, blasts, and hard **slams** into the ground carve the terrain.

## What's implemented

**Combat**
- Free-flight movement with **momentum physics** — gravity, inertia, wall/ground bounce, and **slam impacts** (hit terrain or a wall fast → bonus damage, crater, and a bounce)
- Melee with knockback + punch animation
- Ki-blast projectiles with trails, terrain/wall collisions, and hit detection
- **Chargeable beam attack**: hold to charge (bigger = stronger/thicker/longer), release to fire a sustained beam that melts terrain, knocks back, and can **clash** mid-air when two beams meet (strength-weighted midpoint)
- Blocking (directional damage reduction) with a shield visual

**Charging system**
- Fast ki charge with escalating **power tiers** (1→3): larger aura, rising rings, tier-3 lightning
- **Overcharge / SURGE**: charge past full ki to bank a temporary attack-damage boost (bigger, golden blasts/beams)
- High-tier charging emits a **shockwave** that shoves the opponent and kicks up dirt from the ground

**Destructible terrain**
- Heightmap terrain (the mountains are part of it) that blasts, beams, and slams **carve into real craters** and bore tunnels through — with flying dirt debris

**Rest**
- Finite-state-machine **AI rival** that approaches, blasts, melees, charges to surge, fires beams, and dodges/blocks
- Health + ki + overcharge HUD with tier/SURGE readout, round-start intro, K.O./win-lose, instant rematch
- Juice: hit sparks, screen shake, KO flash, procedural WebAudio SFX (punch, blast, beam, boom)
- Dusk arena: gradient sky, sun, parallax far mountains, stars

## Roadmap → native Android

This web build proves the mechanics and *feel*. Two paths to a real Android app:

1. **Fastest APK (reuse this code):** wrap the web build with **Capacitor** or ship it as a **Trusted Web Activity (TWA)** via Bubblewrap. The game already has touch controls and a mobile viewport, so it runs as-is inside a WebView.
2. **Native game engine (recommended for a polished title):** port the mechanics to **Godot 4** — free, excellent 2D, one-click Android/APK export. The systems here (fighter state, ki, projectiles, AI FSM) map cleanly onto Godot nodes and GDScript.

### Likely next features
- Sprite/animation art pass (idle, fly, punch, charge, hit, KO)
- Full beam-struggle mini-game (mash/steer during a clash)
- Named transformations that consume SURGE for a timed super-mode
- Dash / teleport (double-tap or dedicated button)
- Character roster + simple move variations
- Round system (best of 3), pause menu, settings, haptics
- Difficulty levels for the AI; optional local 2-player

## Files

- `index.html` — the entire game (canvas + game loop + input + AI + audio)
- `README.md` — this file
