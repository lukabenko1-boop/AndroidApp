# KI BLOBS 3D — Aerial Brawl

A playable **3D aerial fighting game** in the *Lemming Ball Z* / Dragon-Ball-Z-arena tradition: two **humanoid fighters** fly around a large 3D arena, trade melee blows, **charge ki**, **transform** into more powerful forms, fire **energy blasts and beams**, and **block** — first to drain the other's health wins.

It's an **original** take (original name, art, and code) so it stays clear of the *Lemmings* and *Dragon Ball* trademarks. The whole thing is a **single self-contained HTML file** with a hand-written **software-3D engine** on a 2D canvas — no external libraries, no WebGL, no build step — so it runs anywhere, including inside a sandboxed page.

## Two versions in this repo

- **`index.html`** — the **web prototype** (guaranteed-runnable, software 3D). Open it in any browser.
- **`godot/`** — a native **Godot 4** port for **real GPU 3D + an Android APK** (lit meshes, shadows, procedural sky, destructible heightmap terrain). See [`godot/README.md`](godot/README.md) to open, run, and export. *Note: it's an author-reviewed scaffold that hasn't been opened in the editor yet (the Godot binary couldn't be fetched in the build sandbox), so expect minor first-run tuning.*

## Play

Open `index.html` in any modern browser (desktop or mobile). No dependencies.

- **Desktop:** double-click the file, or serve the folder: `python3 -m http.server` then visit `http://localhost:8000`.
- **Phone:** open the same URL — on-screen touch controls appear automatically.

## Controls

Movement is on the **horizontal plane** (the blob auto-hovers to the fight's height, so you only steer left/right and near/far):

| Action | Keyboard | Touch |
|---|---|---|
| Move (left/right + near/far, **up = away**) | WASD or Arrow keys | Left stick |
| Punch (melee) | `J` | PUNCH |
| Ki blast | `K` | BLAST |
| Charge ki (hold) | `L` | CHARGE |
| Beam (hold to charge, release to fire) | `I` | BEAM |
| Block (hold) | `Shift` | BLOCK |
| **Transform** (when SURGE is ready) | `T` | auto-prompt in HUD |
| Start / rematch | `Space` | any button |

**Loop:** hold **CHARGE** to fill ki fast; keep charging past a full bar to build **overcharge → SURGE**. With SURGE ready, press **`T`** to **TRANSFORM** into a stronger form (**ASCENDED → SUPER**) — each with its own aura color, bigger damage/speed, and a refilled ki bar that slowly drains while transformed. Spend ki on blasts and beams; close in for free melee; block to cut damage to ~25%. Blasts, beams, and hard **slams** carve craters into the 3D ground.

## What's implemented

**3D engine (software, on canvas)**
- Perspective camera (lookAt) that **follows the midpoint and auto-zooms** to the fighters' separation, with smoothing
- Painter's-algorithm depth sorting + **frustum culling** across terrain, fighters, beams, projectiles, and particles — a **large arena** (~1640 × 1480 units) stays at 60fps
- **Textured, lit, 3D destructible heightmap terrain** — height-banded palette (dirt → grass → rock), directional lighting, slope rock, per-quad variation, and **scorched crater rings**; blasts, beams, and slams carve real craters in the X/Z plane with flying dirt
- **Animated humanoid fighters** — head, torso, arms, and legs with distinct poses for idle, fly, move, punch, charge, beam, block, and hit, plus form-colored spiky hair
- Shadows projected onto the terrain for grounding

**Combat**
- Full-3D flight with momentum, drag, auto-hover altitude, wall/ceiling bounds, and **slam impacts** (crater + bonus damage + bounce)
- Melee with knockback, ki-blast projectiles (3D travel + terrain/target collision), and a **chargeable 3D beam** that melts terrain, knocks back, and **clashes** when two beams meet head-on
- Blocking with directional damage reduction

**Charging & transformations**
- Fast ki charge with escalating **power tiers** (aura, rings, tier-3 lightning) → **overcharge / SURGE**
- **Named transformations** — Base → **ASCENDED** → **SUPER** — each with its own **per-tier aura color** (mirroring LBZ's `Aura_Color_Normal / Transformed / Transformed2`), a damage + speed multiplier folded into a **power-level-style damage model** (`atkMul`), and a timed duration that drains ki

**Rest**
- FSM **AI rival** that approaches, blasts, melees, charges, transforms, fires beams, and dodges
- Health + ki + overcharge HUD with tier / SURGE / form readout, round intro, K.O. flow, instant rematch
- Juice: hit sparks, screen shake, transform flash, procedural WebAudio SFX (punch, blast, beam, boom, transform)
- Dusk arena: gradient sky, sun, stars

## Reference

Design cues were taken from the actual **Lemming Ball Z ALPHA** (build 8581) launcher binaries — a custom C++ "cb9" engine (SDL2 + OpenGL + FMOD, MD5 models, heightmap 3D levels, LGS-scripted moves). We use it as **design reference only** — none of its assets or code are included; KI BLOBS is entirely original.

## Roadmap → native Android

The web build proves the mechanics and feel. Two paths to a real Android app:
1. **Fastest APK:** wrap this build with **Capacitor** or a **TWA** (Bubblewrap) — it already has touch controls + a mobile viewport.
2. **Recommended:** port to **Godot 4** (free, great 3D, one-click APK export). The systems here (fighter state, ki, forms, projectiles, beams, AI, destructible terrain) map cleanly onto Godot nodes and GDScript.

### Likely next features
- Sprite/model art pass; a real camera that orbits and frames the action
- Manual altitude control + dash / teleport
- Full beam-clash mini-game (steer/mash to overpower)
- Data/script-driven moves (à la LBZ's LGS) so moves become editable content
- Round system (best of 3), pause menu, settings, haptics, difficulty levels, local 2-player

## Files

- `index.html` — the entire game (software-3D engine + game loop + input + AI + audio)
- `README.md` — this file
