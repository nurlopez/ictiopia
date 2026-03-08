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
  - Groups for lightnode tracking and subsystem discovery
  - Shaders (`circuit_wave.gdshader`) for organic wave effects
  - AudioStreamPlayer with spectrum analyzer for audio-visual sync
  - AudioBus system for 4-layer soundscape crossfade

## Key Directories

```text
scenes/
├── Main.tscn              # Entry point (instantiates Level1)
├── actors/
│   ├── ictio.tscn         # Player character (CharacterBody2D + PointLight2D)
│   └── ictio.gd           # Movement, particles, stabilize, speed signal
├── environment/
│   ├── Lightnode.tscn     # Rotation puzzle item (Area2D + PointLight2D)
│   ├── lightnode.gd       # Speed-gated rotation, dark→lit states
│   ├── membrane_wall.gd   # Organic chamber walls with shader + splines
│   ├── Portal.tscn        # Level exit (Area2D)
│   └── portal.gd          # Unlocks when all lightnodes fixed
└── ui/
    ├── HUD.tscn           # Head-up display (speed label + node progress)
    ├── hud.gd             # HUD controller
    ├── LevelIntro.tscn    # Intro carousel UI
    ├── level_intro.gd     # Sequential intro with 5 states
    ├── intro_step_*.gd    # Pictogram animations (movement, speed, lightnode, portal)
    └── node_progress.gd   # Fixed-lightnode progress indicator

systems/
├── nervous_system.gd      # Central coordinator: wires Ictio speed → stress → subsystems
├── stress_manager.gd      # Calculates stress from speed vs goldilocks zone
├── circuit_network.gd     # Stress-reactive circuit line visualization
├── circuit_line.gd        # Circuit line rendering with Catmull-Rom splines
├── soundscape_manager.gd  # 4-layer audio crossfade (calm→stress)
└── audio_visual_sync.gd   # Bridges audio intensity to visual effects

shaders/
└── circuit_wave.gdshader  # Wave distortion shader (circuit lines + membrane walls)

levels/
├── Level1.tscn            # Complete level scene (dark atmosphere, 3 chambers)
├── level_controller.gd    # Lightnode tracking, progressive world lighting
├── chamber_layout.gd      # Spawns membrane wall instances at runtime
└── speed_label.gd         # Debug speed display

assets/
├── art/
│   ├── ictio/             # Character animation frames (2 styles)
│   ├── lightnodes/        # Lightnode icons (lightnode-01, 02, 03)
│   ├── tile.png           # Level tileset
│   └── bubble.png         # Particle texture + light texture
└── audio/                 # Soundscape layers (calm, tension, ambience, heartbeat, etc.)
```

## Run / Build Notes

### Running Locally

1. Open Godot 4.3
2. Import `project.godot`
3. Press F5 or click Play

### Controls

- **WASD** or **Arrow keys**: Move Ictio
- **Space**: Stabilize (hold to maintain current speed with dampened acceleration)
- Moderate speed (40-160 px/s) to rotate lightnodes

### Export

No export presets configured yet.

## Core Mechanics (for context)

|Mechanic|Description|
|--------|-----------|
|**Speed moderation**|Goldilocks zone: 40-160 px/s required to rotate lightnodes|
|**Stabilize**|Hold spacebar to dampen acceleration and maintain current speed (glow feedback)|
|**Lightnode rotation**|Touch lightnodes to rotate; match target angle to fix|
|**Dark→Lit states**|Lightnodes start dim (30% alpha), glow brightly when fixed|
|**Point lights**|Fixed lightnodes emit PointLight2D to illuminate surroundings|
|**Progressive lighting**|World brightens via CanvasModulate as lightnodes are fixed|
|**Nervous system/stress**|NervousSystem calculates stress from speed; fans out to circuit network, soundscape, membrane walls|
|**Circuit network**|Visual circuit lines react to stress level via wave shader|
|**Membrane walls**|Organic chamber boundaries using Catmull-Rom splines + circuit_wave shader|
|**Soundscape**|4-layer audio crossfade (calm/neutral/tense/stress) driven by stress level|
|**Intro tutorial**|Pictogram-based carousel teaches movement, speed, lightnodes, and portal mechanics|
|**HUD**|Speed display + lightnode progress indicator|
|**Portal unlock**|Opens when all lightnodes are fixed|

## Signal Flow

```text
Ictio.speed_changed → NervousSystem → StressManager.on_speed_changed()
StressManager.stress_changed → NervousSystem → fan-out via groups:
    → CircuitNetwork (circuit_network group)
    → SoundscapeManager (soundscape_manager group)
    → MembraneWalls (membrane_walls group)
SoundscapeManager.audio_intensity_changed → AudioVisualSync.pulse_changed → CircuitNetwork
Lightnode.body_entered → rotation logic, notify_lightnode_fixed()
LevelController.all_lightnodes_fixed → Portal.open_portal()
LevelIntro.intro_dismissed → LevelController._on_intro_dismissed()
```

## Additional Documentation

- [Core Mechanics](.claude/docs/mechanics.md) — Progressive ruleset and design intent
- [Architectural Patterns](.claude/docs/architectural_patterns.md) — Code patterns in use
- [Soundscape Design](.claude/docs/soundscape.md) — Audio layers and stress-driven crossfade
