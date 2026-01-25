# Architectural Patterns

Patterns observed across this prototype. Architecture is still evolving.

## 1. Signal-Based Event Flow

Decoupled communication via Godot signals. No hard references between systems.

```gdscript
# Emitter (ictio.gd)
signal speed_changed(speed: float)
speed_changed.emit(velocity.length())

# Receiver (level_controller.gd)
ictio.speed_changed.connect(_on_ictio_speed_changed)
```

**Used in:** Ictio→LevelController, LevelController→Portal, Collectible→LevelController

## 2. Unique Names for Node Access

Nodes use `unique_name_in_owner` for `%NodeName` syntax, avoiding fragile paths.

**Current unique names:** `%Tint`, `%Audio`, `%Ictio`, `%Portal`, `%LevelController`

## 3. Stress as Central Game State

LevelController owns the stress metric. Other systems query or modify it:

- **Ictio** reports speed (LevelController calculates stress gain)
- **Collectibles** call `reduce_stress()` and check threshold
- **Visuals/Audio** interpolate based on `stress_view`

## 4. Deferred Calls for Safe Updates

Physics properties and node counting use deferred calls:

```gdscript
call_deferred("_late_count_collectibles")
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
- **Level scenes** compose actors, environment, and controllers
- **Reusable scenes** (Ictio, Collectible, Portal) are instanced with per-instance exports
