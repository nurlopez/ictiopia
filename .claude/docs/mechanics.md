# Core Mechanics — Progressive Ruleset

Ictiopia's mechanics are introduced progressively, each layer building on the previous. This creates a learning curve that mirrors the game's themes of sensory regulation and intentional action.

---

## Mechanic I — Speed Moderation

> **Foundation mechanic. Introduced first, persists through all levels.**

### Rules (Mechanic I)

- Objects rotate only when Ictio bumps into them at **moderate speed**
- Too fast → no effect (overstimulated, frantic)
- Too slow → no effect (disengaged, passive)
- The "Goldilocks zone" must be learned through experimentation

### Design Purpose (Mechanic I)

- Teach controlled, intentional movement
- Introduce sensory consequence tied to speed
- Establish that rushing or hesitating both fail

### Win Condition (Mechanic I)

Rotate all required objects to their target angles.

### Implementation Notes (Mechanic I)

| Parameter | Description |
| --------- | ----------- |
| `min_effective_speed` | Below this, bumps have no effect |
| `max_effective_speed` | Above this, bumps have no effect |
| `angle_step_deg` | Rotation increment per valid bump |
| `required_angle_deg` | Target angle to "solve" the object |

---

## Mechanic II — Order & Sequence

> **Layered on top of Speed Moderation.**

### Rules (Mechanic II)

- Objects must be rotated in a **specific order**
- Speed Moderation rules still apply
- Bumping an object out of sequence → no rotation, no progress
- Visual/audio feedback distinguishes "wrong order" from "wrong speed"

### Design Purpose (Mechanic II)

- Introduce structure and planning ahead
- Reinforce intentional, deliberate action over impulsive movement
- Require observation before action

### Win Condition (Mechanic II)

Rotate all objects in the correct sequence, each at moderate speed.

### Implementation Notes (Mechanic II)

| Parameter | Description |
| --------- | ----------- |
| `sequence_index` | Current position in the required order |
| `object_order[]` | Array defining the correct activation sequence |
| `sequence_hint` | Optional visual cue showing next target |

---

## Mechanic III — Pattern Association (Colour Matching)

> **Layered on top of Speed Moderation + Order & Sequence.**

### Rules (Mechanic III)

- Objects must be:
  1. Hit at moderate speed
  2. Activated in the correct order
  3. **Matched to the current background colour**
- Background colour changes over time (cyclic or reactive)
- Objects can only be activated when their colour matches the background
- Hitting a mismatched object → no effect (or penalty)

### Design Purpose (Mechanic III)

- Add timing and perceptual problem-solving
- Represent heightened pattern sensitivity (sensory theme)
- Create waiting as a valid strategy — patience is rewarded

### Win Condition (Mechanic III)

Complete the sequence with correct colour timing.

### Implementation Notes (Mechanic III)

| Parameter | Description |
| --------- | ----------- |
| `background_color` | Current active colour (cycles or shifts) |
| `color_cycle_time` | Duration of each colour phase |
| `object_color` | Each object's assigned colour |
| `color_match_tolerance` | How close colours must be to count as "matching" |

---

## Mechanic IV — Energy & Calm Zones

> **Final layer. All previous mechanics apply.**

### Rules (Mechanic IV)

- Ictio has **limited energy**
- Energy drains:
  - Passively over time
  - Faster through overstimulation (high speed, collisions, wrong actions)
- Player must reach the relevant coloured object before energy runs out
- **Calm Zones**:
  - Restore energy
  - Reduce sensory overload (stress)
  - Act as safe havens for planning

### Design Purpose (Mechanic IV)

- Introduce emotional regulation as a mechanical necessity
- Prevent brute-force or rushed solutions
- Create tension between urgency (energy drain) and control (speed moderation)
- Calm Zones embody the need for intentional rest

### Win Condition (Mechanic IV)

Successfully complete all interactions before energy depletion.

### Implementation Notes (Mechanic IV)

| Parameter | Description |
| --------- | ----------- |
| `max_energy` | Energy capacity |
| `energy_drain_rate` | Passive drain per second |
| `overstim_drain_multiplier` | Extra drain when overspeeding |
| `calm_zone_restore_rate` | Energy restored per second in Calm Zone |
| `calm_zone_stress_reduction` | Stress reduction while in Calm Zone |

---

## Progression Summary

| Level Tier | Active Mechanics |
| ---------- | ---------------- |
| **Tier 1** | Speed Moderation only |
| **Tier 2** | + Order & Sequence |
| **Tier 3** | + Colour Matching |
| **Tier 4** | + Energy & Calm Zones (full ruleset) |

Each tier should have multiple levels to allow mastery before the next mechanic is introduced.

---

## Failure States

| Mechanic | Failure Trigger | Feedback |
| -------- | --------------- | -------- |
| Speed Moderation | Wrong speed | Object wobbles but doesn't rotate |
| Order & Sequence | Wrong object | Visual flash, sequence hint |
| Colour Matching | Colour mismatch | Object dims, wait for correct phase |
| Energy | Energy depleted | Fade to black, gentle restart |

---

## Thematic Alignment

These mechanics are designed to mirror experiences of sensory processing:

- **Speed Moderation** → Finding the right level of stimulation
- **Order & Sequence** → Need for structure and predictability
- **Colour Matching** → Pattern recognition under changing conditions
- **Energy & Calm Zones** → Managing overwhelm, knowing when to rest
