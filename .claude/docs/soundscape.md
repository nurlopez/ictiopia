# Soundscape System — Audio Brief

## How it works

The game runs **4 audio layers simultaneously**, all looping. Only their volumes change. As the player moves outside the safe speed zone (40-160 px/s), a **stress value** (0.0-1.0) rises. This stress value crossfades between layers.

All 4 layers play through a dedicated **Soundscape** audio bus with a spectrum analyzer. Bass frequencies (20-200 Hz) are extracted in real time and routed to the circuit lines connecting lightnodes, making them visually pulse and distort in sync with the audio.

## The 4 layers

| Layer | Stress range | Role | Current file |
|-------|-------------|------|--------------|
| **Calm** | 0.0 - 0.3 | Default atmosphere. Full volume at rest, fades out as stress rises. | `calm.mp3` |
| **Neutral** | 0.0 - 0.6 | Subtle bed that spans calm-to-mid stress. Always present but never dominant. | `distant-signal-drone-74016.mp3` |
| **Tense** | 0.2 - 0.8 | Builds as player pushes speed limits. **Pitch increases** with stress (0.8x to 1.4x). | `tension.mp3` |
| **Stress** | 0.5 - 1.0 | Maximum danger. Only audible at high stress, becomes dominant at full stress. | `weird-pulse-sonar-sound-64566.mp3` |

### Volume crossfade behavior

```
Stress:  0.0 ──────── 0.3 ──── 0.5 ──── 0.8 ──── 1.0
Calm:    ████████░░░░░
Neutral: ░░████████████░░░░░
Tense:        ░░░░████████████░░
Stress:                 ░░░░████████████
```

Transitions are smooth (lerped at ~2 dB/s). Layers overlap in their ranges so there are no silent gaps.

## Audio-visual sync

The circuit lines (nervous system connections between lightnodes) react to the audio:

- **Bass frequencies** (20-200 Hz) drive a pulse value sent to the line shader
- Lines **undulate** with sine-wave distortion that intensifies with stress
- Lines **glow brighter** during audio peaks
- Lines **distort more** when the player is nearby or moving too fast/slow

This means **rhythmic audio content directly translates to visible line movement**. Tracks with clear bass pulses will produce the strongest visual effect.

## Guidelines for the musician

### What matters most

- **Bass content drives visuals.** The 20-200 Hz range is extracted by the spectrum analyzer. Rhythmic bass = visible line pulsing. Flat bass = static lines.
- **Each layer should loop seamlessly.** All 4 tracks play on repeat for the duration of gameplay.
- **Layers must blend well together.** At mid-stress (0.3-0.5), calm, neutral, and tense all overlap. They need to coexist without clashing.

### Per-layer notes

**Calm** — The player hears this most of the time. Should feel like the natural ambient sound of an underwater jellyfish planet. Gentle, immersive, not distracting. Light bass presence is fine but not required for visuals at this stress level.

**Neutral** — A subtle connective layer. Think of it as tonal glue between calm and tense. It's always partly audible, so it shouldn't draw attention. Works well as a low drone or pad.

**Tense** — This is where rhythmic bass matters. The pitch scales up with stress (0.8x-1.4x), so it should sound coherent across that range. A rhythmic or pulsing quality here will make the circuit lines visibly react as stress builds. The original placeholder was a heartbeat — that kind of rhythmic character works well.

**Stress** — Maximum danger. Only heard when the player is significantly overspeeding. Should feel urgent/alarming. Strong bass pulses here will produce the most dramatic line distortion. This layer dominates the mix at high stress, so it can be more intense.

### Technical specs

- Format: MP3 (or OGG Vorbis)
- All tracks should be **loopable** (seamless start-to-end)
- No specific length requirement, but 30-60 seconds is typical for ambient loops
- Moderate loudness — the system handles volume mixing via code
