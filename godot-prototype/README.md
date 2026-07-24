# KI Blobs — first 3D prototype (Godot 4)

The **minimal** Godot 4 starting point: one script, one scene, high confidence it
runs on first open. A controllable fighter flies over a 3D heightmap arena with a
follow camera, a target dummy, and a simple blast.

Use this as the foundation to grow from. The **full-feature** version (destructible
terrain, beams, transformations, AI, HUD, touch, Android export) lives in
[`../godot/`](../godot); the browser build is [`../index.html`](../index.html).

## Run

1. Open **Godot 4.3+** → Import → select `godot-prototype/project.godot`.
2. Press **F5**. `Proto.tscn` is the main scene.

## Controls

| Action | Key |
|---|---|
| Move (x + depth, up = away) | WASD / Arrows |
| Ascend | Space |
| Descend | Shift |
| Blast | J |

## What it does (all built in code from one Node3D)

- Procedural sky + directional sun with shadows
- A small **3D heightmap terrain** (SurfaceTool mesh, vertex-coloured dirt/grass/rock),
  with height sampling so the fighter lands on the surface
- A **flyable humanoid** (capsule + head) with momentum, gravity, and manual altitude
- A **follow camera** and a red **target dummy**
- A simple **ki blast** (`J`) that flies forward and fades

## Next steps

Layer systems on one at a time — melee, ki/charge, an AI opponent, health bars —
or jump straight to the full version in `../godot/`.
