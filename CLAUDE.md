# Ictiopia_2D

## Project Overview

**Ictiopia** is a jellyfish-like glowing planet in blackout. The player controls **Ictio**, a fish mechanic who moves through different areas rotating **lightnodes** to restore the light. Because the jellyfishverse is sensitive to Ictio's movements, each lightnode must be fixed at a precise speed learned through gameplay.

## Tech Stack

- **Godot 4.3** (Forward Plus rendering)
- **GDScript** exclusively
- **Notable features in use:**
  - CharacterBody2D physics with acceleration/friction
  - GPUParticles2D for dynamic bubble trails
  - PointLight2D for lightnode illumination
  - Signals for decoupled communication
  - Unique names (`%NodeName`) for flexible node access
  - CanvasModulate for progressive world lighting
  - AnimationPlayer for UI/portal animations
  - Groups for lightnode tracking

## Key Directories

```text
scenes/
├── Main.tscn              # Entry point (instantiates Level1)
├── actors/
│   ├── ictio.tscn         # Player character (CharacterBody2D + PointLight2D)
│   └── ictio.gd           # Movement, particles, speed signal
└── environment/
    ├── Lightnode.tscn     # Rotation puzzle item (Area2D + PointLight2D)
    ├── lightnode.gd       # Speed-gated rotation, dark→lit states
    ├── Portal.tscn        # Level exit (Area2D)
    └── portal.gd          # Unlocks when all lightnodes fixed

levels/
├── Level1.tscn            # Complete level scene (dark atmosphere)
├── level_controller.gd    # Lightnode tracking, progressive world lighting
└── speed_label.gd         # UI speed display

assets/art/
├── ictio/                 # Character animation frames (2 styles)
├── lightnodes/            # Lightnode icons (lightnode-01, 02, 03)
├── tile.png               # Level tileset
└── bubble.png             # Particle texture + light texture
```

## Run / Build Notes

### Running Locally

1. Open Godot 4.3
2. Import `project.godot`
3. Press F5 or click Play

### Controls

- **WASD** or **Arrow keys**: Move Ictio
- Moderate speed (40-160 px/s) to rotate lightnodes

### Export

No export presets configured yet.

## Core Mechanics (for context)

|Mechanic|Description|
|--------|-----------|
|**Speed moderation**|Goldilocks zone: 40-160 px/s required to rotate lightnodes|
|**Lightnode rotation**|Touch lightnodes to rotate; match target angle to fix|
|**Dark→Lit states**|Lightnodes start dim (30% alpha), glow brightly when fixed|
|**Point lights**|Fixed lightnodes emit PointLight2D to illuminate surroundings|
|**Progressive lighting**|World brightens via CanvasModulate as lightnodes are fixed|
|**Portal unlock**|Opens when all lightnodes are fixed|

## Signal Flow

```text
Ictio.speed_changed → (broadcast for UI/debug)
Lightnode.body_entered → rotation logic, notify_lightnode_fixed()
LevelController.all_lightnodes_fixed → Portal.open_portal()
```

## Additional Documentation

- [Core Mechanics](.claude/docs/mechanics.md) — Progressive ruleset and design intent
- [Architectural Patterns](.claude/docs/architectural_patterns.md) — Code patterns in use
