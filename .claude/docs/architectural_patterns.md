# Architectural Patterns

Patterns observed across this prototype. Architecture is still evolving.

## 1. Signal-Based Event Flow

Decoupled communication via Godot signals. No hard references between systems.

```gdscript
# Emitter (ictio.gd)
signal speed_changed(speed: float)
speed_changed.emit(velocity.length())

# Receiver (nervous_system.gd)
ictio.speed_changed.connect(_stress_manager.on_speed_changed)
```

**Used in:** Ictio→NervousSystem→StressManager, StressManager→NervousSystem→subsystems, LevelController→Portal, LevelIntro→LevelController

## 2. Unique Names for Node Access

Nodes use `unique_name_in_owner` for `%NodeName` syntax, avoiding fragile paths.

**Current unique names:** `%Tint`, `%Audio`, `%Background`, `%Ictio`, `%Portal`, `%LevelController`, `%NervousSystem`, `%LevelIntro`, `%NodeProgress`, `%HUD`, `%SpeedLabel`

## 3. Stress as Central Game State

NervousSystem is the central coordinator. StressManager owns the stress metric. Other systems react via signal fan-out:

- **Ictio** reports speed → NervousSystem → StressManager calculates stress
- **StressManager** emits `stress_changed` → NervousSystem routes to subsystems via group iteration
- **CircuitNetwork** adjusts visual intensity based on stress
- **SoundscapeManager** crossfades audio layers based on stress
- **MembraneWalls** react visually to stress level

## 4. Deferred Calls for Safe Updates

Physics properties and node counting use deferred calls:

```gdscript
call_deferred("_late_count_lightnodes")
set_deferred("monitoring", false)
```

## 5. Exponential Smoothing for Visual Feedback

`stress_view` smooths toward `stress` to prevent jittery UI:

```gdscript
var a := 1 - exp(-view_lerp_speed * delta)
stress_view = lerpf(stress_view, stress, a)
```

## 6. Scene Composition Style

- **Main.tscn** instantiates level scenes (currently only Level1)
- **Level scenes** compose actors, environment, systems, and controllers
- **Reusable scenes** (Ictio, Lightnode, Portal) are instanced with per-instance exports

## 7. NervousSystem Signal Fan-Out

NervousSystem routes `stress_changed` to subsystems via group iteration rather than direct references. Each subsystem registers itself in a group (e.g., `circuit_network`, `soundscape_manager`, `membrane_walls`), and NervousSystem iterates the group to call update methods.

```gdscript
# nervous_system.gd routes stress to all subsystems via groups
for node in get_tree().get_nodes_in_group("circuit_network"):
    node.on_stress_changed(stress_level)
```

**Benefit:** Adding new stress-reactive subsystems requires no changes to NervousSystem.

## 8. Catmull-Rom Splines for Organic Curves

Circuit lines and membrane walls use Catmull-Rom spline interpolation for smooth, organic-looking curves. The algorithm is implemented in `circuit_line.gd` (lines ~105-149) and reused in `membrane_wall.gd`.

**Used for:** Circuit network lines, membrane wall boundaries between chambers.

## 9. Shader Reuse with Different Uniforms

`circuit_wave.gdshader` is a single wave distortion shader applied to both circuit lines and membrane walls. Each instance uses different uniform values (frequency, amplitude, speed) to create distinct visual effects from the same shader code.
