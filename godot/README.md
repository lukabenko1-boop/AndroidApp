# KI Blobs 3D — Godot 4 project

A native **Godot 4** port of the KI BLOBS aerial fighter (the web prototype lives in
`../index.html`). This version uses **real GPU 3D**: lit meshes and shadows, a
procedural sky, humanoid fighters built from primitives, and a **destructible 3D
heightmap terrain** — targeting a **one-click Android APK**.

> ⚠️ **Status: author-reviewed scaffold, not yet run in-engine.** It was written in a
> sandbox where the Godot binary couldn't be downloaded (network policy), so it has
> **not been opened in the editor here**. Expect to do a little tuning on first run
> (limb poses, camera framing, colours). The web build in `../index.html` remains the
> guaranteed-runnable reference.

## Requirements

- **Godot 4.3** (or 4.2+/4.4 — adjust `config/features` in `project.godot` if prompted).
  Standard build; no C#/.NET needed (pure GDScript).
- For Android export: **Android build template + SDK** (see below).

## Open & run

1. Launch Godot 4.3 → **Import** → select `godot/project.godot`.
2. Let it import, then press **F5** (Play). `Main.tscn` is the main scene.

Everything (world, camera, HUD, touch UI) is built in code from `scripts/Main.gd`, so
there are no fragile scene files to break — just the one-node `Main.tscn`.

## Controls

Movement is on the horizontal plane; altitude auto-hovers to the fight.

| Action | Keyboard | Touch |
|---|---|---|
| Move (x + depth, **up = away**) | WASD / Arrows | Left stick |
| Punch | `J` | PUNCH |
| Ki blast | `K` | BLAST |
| Charge ki (hold) | `L` | CHARGE |
| Beam (hold → release) | `I` | BEAM |
| Block (hold) | `Shift` | BLOCK |
| Transform (when SURGE ready) | `T` | (auto-prompt; add a button if you like) |
| Start / rematch | `Space` | any button |

## What's implemented

- **`Terrain.gd`** — 40×36 destructible heightmap `ArrayMesh` with per-vertex
  dirt/grass/rock colours; `carve()` lowers vertices (craters) from blasts, beams, and
  slams and rebuilds once per frame; `height_at()` bilinear sampling for collisions.
- **`Fighter.gd`** — humanoid built from primitives (head, torso, arm/leg pivots, hair
  cone, emissive aura sphere + light, world-space beam cylinder). Ports the full system
  set: 3D flight + auto-hover, drag/slam physics, melee, blasts, chargeable **beams**,
  ki **charge → tiers → SURGE**, **transformations** (Base/Ascended/Super with per-form
  aura colours and a power-level-style `atk_mul`), blocking, and a finite-state-machine
  **AI**.
- **`Projectile.gd`** — emissive ki blast with a glow light; carves terrain / damages on hit.
- **`Main.gd`** — world build (procedural sky, sun + shadows, fog, follow-and-zoom
  camera), title/playing/K.O. state machine, keyboard + touch input, transform bursts,
  camera shake.
- **`Hud.gd`** — immediate-mode HP/ki/overcharge bars, names, form labels, and overlays.

## Export an Android APK

1. **Editor → top menu → Editor → Manage Export Templates → Download and Install**
   (matches your Godot version).
2. Install the **Android SDK** (Android Studio, or command-line tools) and set paths in
   **Editor → Editor Settings → Export → Android** (Java SDK / Android SDK / debug keystore).
   Godot can generate a debug keystore for you.
3. **Project → Export → Add… → Android.** Set a unique package name
   (e.g. `com.yourname.kiblobs`). The renderer is already `gl_compatibility` (mobile)
   and orientation is landscape.
4. **Export Project** (or **Export APK**) → install the `.apk` on your device
   (`adb install kiblobs.apk`).

See the Godot docs: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>

## Known follow-ups

- Tune limb-pose angles and camera distance on first run.
- Swap primitive humanoids for a rigged model + `AnimationPlayer` when you want real animation.
- Optional: add a dedicated on-screen **TRANSFORM** button and a manual altitude control.
- Optimise `Terrain.rebuild()` (only re-emit changed cells) if you target low-end phones.
