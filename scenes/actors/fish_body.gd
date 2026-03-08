extends Node2D
## Procedural fish outline matching the icon reference:
## bold stroke, no fill, forked tail with peduncle, subtle ventral fin, eye dot.
## Tail sway + body wave driven by parent swim speed.

var _phase: float = 0.0
var _swim_speed: float = 0.0

const LINE_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const LINE_WIDTH := 1.0
const EYE_RADIUS := 2.8

func _process(delta: float) -> void:
	var parent := get_parent() as CharacterBody2D
	if parent:
		_swim_speed = parent.velocity.length()

	var freq: float = remap(clampf(_swim_speed, 0.0, 200.0), 0.0, 200.0, 2.0, 9.0)
	_phase += freq * delta
	queue_redraw()

func _draw() -> void:
	var sway_amp: float = remap(clampf(_swim_speed, 0.0, 200.0), 0.0, 200.0, 1.5, 6.0)
	var wave_amp: float = remap(clampf(_swim_speed, 0.0, 200.0), 0.0, 200.0, 0.3, 2.0)
	var sway: float = sin(_phase) * sway_amp

	# --- Build outline key-points ---
	var keys: PackedVector2Array = _key_points(sway)

	# --- Catmull-Rom subdivide (closed-loop aware) for silky curves ---
	var smooth: PackedVector2Array = _subdivide_closed(keys, 8)

	# --- Apply travelling body wave (stronger toward tail) ---
	for i in range(smooth.size()):
		var t: float = clampf(remap(smooth[i].x, 24.0, -28.0, 0.0, 1.0), 0.0, 1.0)
		smooth[i].y += sin(_phase + t * 2.5) * t * t * wave_amp

	draw_polyline(smooth, LINE_COLOR, LINE_WIDTH, true)

	# --- Eye (apply same wave) ---
	var eye_pos := Vector2(10.0, -3.5)
	var eye_t: float = clampf(remap(eye_pos.x, 24.0, -28.0, 0.0, 1.0), 0.0, 1.0)
	eye_pos.y += sin(_phase + eye_t * 2.5) * eye_t * eye_t * wave_amp
	draw_circle(eye_pos, EYE_RADIUS, LINE_COLOR)

# ── Key-point outline (fish faces RIGHT) ─────────────────────────────
func _key_points(sway: float) -> PackedVector2Array:
	var fin_wave: float = sin(_phase * 1.4) * 1.0

	return PackedVector2Array([
		# ── Nose (gently rounded) ──
		Vector2(24.0, -1.0),

		# ── Dorsal arc ──
		Vector2(22.0, -4.5),
		Vector2(18.0, -8.5),
		Vector2(12.0, -12.0),
		Vector2(4.0, -14.0),
		Vector2(-4.0, -14.0),
		Vector2(-10.0, -12.0),
		Vector2(-14.0, -8.5),

		# ── Caudal peduncle (body narrows to thin neck) ──
		Vector2(-17.0, -5.0),
		Vector2(-19.0, -3.0),

		# ── Upper tail prong (convex outer curve) ──
		Vector2(-21.0, -5.5 + sway * 0.5),
		Vector2(-24.0, -8.5 + sway * 0.8),
		Vector2(-28.0, -10.5 + sway),

		# ── Tail notch (smooth concave) ──
		Vector2(-23.0, -3.0 + sway * 0.4),
		Vector2(-21.0, sway * 0.25),
		Vector2(-23.0, 3.0 + sway * 0.4),

		# ── Lower tail prong (convex outer curve) ──
		Vector2(-28.0, 10.5 + sway),
		Vector2(-24.0, 8.5 + sway * 0.8),
		Vector2(-21.0, 5.5 + sway * 0.5),

		# ── Caudal peduncle (lower) ──
		Vector2(-19.0, 3.0),
		Vector2(-17.0, 5.0),

		# ── Ventral body (fuller belly) ──
		Vector2(-14.0, 8.5),
		Vector2(-10.0, 11.5),
		Vector2(-5.0, 13.0),

		# ── Ventral fin (subtle angular dip under mid-belly) ──
		Vector2(-1.0, 13.0),
		Vector2(-2.5, 16.0 + fin_wave),
		Vector2(-5.0, 12.5),

		# ── Belly forward to nose (plump underbelly) ──
		Vector2(1.0, 13.0),
		Vector2(7.0, 11.0),
		Vector2(13.0, 7.5),
		Vector2(18.0, 4.0),
		Vector2(22.0, 1.5),

		# ── Close at nose ──
		Vector2(24.0, -1.0),
	])

# ── Catmull-Rom subdivision (closed-loop) ─────────────────────────────
# Wraps tangent calculation around the seam so the nose has no cusp.
func _subdivide_closed(pts: PackedVector2Array, steps: int) -> PackedVector2Array:
	# Last point == first point, so the "loop" has count-1 unique segments.
	var n: int = pts.size() - 1  # number of unique points
	if n < 3:
		return pts

	var result := PackedVector2Array()
	for i in range(n):
		# Wrap indices for closed loop
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n]

		for s in range(steps):
			var t: float = float(s) / float(steps)
			result.append(_catmull_rom(p0, p1, p2, p3, t))

	# Close the loop
	result.append(pts[0])
	return result

func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
