class_name FishDrawUtils
## Shared procedural fish outline drawing used by both the game (fish_body.gd)
## and intro carousel pictograms.
##
## The fish faces RIGHT at ~52px wide at scale 1.0.
## Use draw_set_transform before calling, or use the convenience draw_fish().

## Draw the fish outline + eye on `ci` at `pos`.
## scl: 1.0 = full size (~52px). Game uses 0.8, intro uses 0.4-0.6.
## color: outline + eye fill.
## rot: facing angle (0 = right, PI = left).
## sway: tail offset in px (pass sin(t) * amp for animation, 0 for static).
## flip_h: mirror horizontally (fish faces left without rotating vertically).
static func draw_fish(ci: CanvasItem, pos: Vector2, scl: float, color: Color,
		rot: float = 0.0, sway: float = 0.0, flip_h: bool = false) -> void:
	var sx: float = -scl if flip_h else scl
	ci.draw_set_transform(pos, rot, Vector2(sx, scl))

	var keys := _key_points(sway)
	var smooth := _subdivide_closed(keys, 6)
	ci.draw_polyline(smooth, color, 1.0, true)
	ci.draw_circle(Vector2(10.0, -3.5), 2.8, color)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── Key-point outline (fish faces RIGHT) ─────────────────────────────
static func _key_points(sway: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(24.0, -1.0),
		Vector2(22.0, -4.5),
		Vector2(18.0, -8.5),
		Vector2(12.0, -12.0),
		Vector2(4.0, -14.0),
		Vector2(-4.0, -14.0),
		Vector2(-10.0, -12.0),
		Vector2(-14.0, -8.5),
		Vector2(-17.0, -5.0),
		Vector2(-19.0, -3.0),
		Vector2(-21.0, -5.5 + sway * 0.5),
		Vector2(-24.0, -8.5 + sway * 0.8),
		Vector2(-28.0, -10.5 + sway),
		Vector2(-23.0, -3.0 + sway * 0.4),
		Vector2(-21.0, sway * 0.25),
		Vector2(-23.0, 3.0 + sway * 0.4),
		Vector2(-28.0, 10.5 + sway),
		Vector2(-24.0, 8.5 + sway * 0.8),
		Vector2(-21.0, 5.5 + sway * 0.5),
		Vector2(-19.0, 3.0),
		Vector2(-17.0, 5.0),
		Vector2(-14.0, 8.5),
		Vector2(-10.0, 11.5),
		Vector2(-5.0, 13.0),
		Vector2(-1.0, 13.0),
		Vector2(-2.5, 16.0),
		Vector2(-5.0, 12.5),
		Vector2(1.0, 13.0),
		Vector2(7.0, 11.0),
		Vector2(13.0, 7.5),
		Vector2(18.0, 4.0),
		Vector2(22.0, 1.5),
		Vector2(24.0, -1.0),
	])

# ── Catmull-Rom subdivision (closed-loop) ─────────────────────────────
static func _subdivide_closed(pts: PackedVector2Array, steps: int) -> PackedVector2Array:
	var n: int = pts.size() - 1
	if n < 3:
		return pts

	var result := PackedVector2Array()
	for i in range(n):
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n]

		for s in range(steps):
			var t: float = float(s) / float(steps)
			result.append(_catmull_rom(p0, p1, p2, p3, t))

	result.append(pts[0])
	return result

static func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
