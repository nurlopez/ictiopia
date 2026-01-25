# Ictiopia_2D

## Project Overview

Underwater puzzle game prototype exploring **stress as a core mechanic**. The player controls Ictio, a small aquatic creature, collecting rotation-puzzle items while managing a stress meter that gates progression. Moving too fast increases stress; calm movement is rewarded.

## Tech Stack

- **Godot 4.3** (Forward Plus rendering)
- **GDScript** exclusively
- **Notable features in use:**
  - CharacterBody2D physics with acceleration/friction
  - GPUParticles2D for dynamic bubble trails
  - Signals for decoupled communication
  - Unique names (`%NodeName`) for flexible node access
  - CanvasModulate for real-time screen tinting
  - AnimationPlayer for UI/portal animations
  - Groups for collectible tracking

## Key Directories

```text
scenes/
├── Main.tscn              # Entry point (instantiates Level1)
├── actors/
│   ├── ictio.tscn         # Player character (CharacterBody2D)
│   └── ictio.gd           # Movement, particles, speed signal
└── environment/
    ├── Collectible.tscn   # Rotation puzzle item (Area2D)
    ├── collectible.gd     # Stress-gated pickup logic
    ├── Portal.tscn        # Level exit (Area2D)
    └── portal.gd          # Unlocks when all collectibles gathered

levels/
├── Level1.tscn            # Complete level scene
├── level_controller.gd    # Stress system, collectible tracking, visuals
└── stress_label.gd        # UI stress display

assets/art/
├── ictio/                 # Character animation frames (2 styles)
├── collectibles/          # Shape icons (circle, hexagon, triangle)
├── tile.png               # Level tileset
└── bubble.png             # Particle texture
```

## Run / Build Notes

### Running Locally

1. Open Godot 4.3
2. Import `project.godot`
3. Press F5 or click Play

### Controls

- **WASD** or **Arrow keys**: Move Ictio
- Stay calm (slow movement) to collect items

### Export

No export presets configured yet.

## Core Mechanics (for context)

|Mechanic|Description|
|--------|-----------|
|**Stress accumulation**|Speed > 120 increases stress quadratically|
|**Stress decay**|Slow movement reduces stress (1.4/sec)|
|**Collectible gates**|Require stress < 30 to pick up|
|**Rotation puzzles**|Touch collectibles to rotate; match target angle|
|**Portal unlock**|Opens when all collectibles collected|
|**Visual feedback**|Screen tint shifts cyan→purple with stress|

## Signal Flow

```text
Ictio.speed_changed → LevelController._on_ictio_speed_changed()
LevelController.all_collectibles_cleared → Portal.open_portal()
Collectible.body_entered → rotation/pickup logic
```

## Additional Documentation

- [Core Mechanics](.claude/docs/mechanics.md) — Progressive ruleset and design intent
- [Architectural Patterns](.claude/docs/architectural_patterns.md) — Code patterns in use
