extends Node2D

## Pictogram: Movement — fish with 4 organic directional tendrils.

var _time_offset: float = 0.0
const FISH_SCALE := 0.6
const FISH_COLOR := Color(1.0, 1.0, 1.0, 0.9)


func reset_animation() -> void:
	_time_offset = Time.get_ticks_msec() / 1000.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := (Time.get_ticks_msec() / 1000.0) - _time_offset

	# Fish bob gently
	var bob := Vector2(sin(t * 0.9) * 2.0, cos(t * 1.1) * 1.5)
	var sway := sin(t * 2.5) * 2.0

	# Draw fish at center
	FishDrawUtils.draw_fish(self, bob, FISH_SCALE, FISH_COLOR, 0.0, sway)

	# Four directional organic tendrils
	var directions := [
		Vector2.UP,
		Vector2.RIGHT,
		Vector2.DOWN,
		Vector2.LEFT,
	]

	for i in range(4):
		var dir: Vector2 = directions[i]
		var phase: float = float(i) * 0.7
		# Pulse each arrow in sequence (one brightens while others dim)
		var cycle: float = fmod(t * 0.6, 4.0)
		var dist_to_active: float = absf(fmod(cycle - float(i) + 4.0, 4.0))
		if dist_to_active > 2.0:
			dist_to_active = 4.0 - dist_to_active
		var brightness: float = 1.0 - clampf(dist_to_active / 1.5, 0.0, 1.0)
		brightness = 0.25 + brightness * 0.75  # never fully invisible

		_draw_tendril(bob, dir, t, phase, brightness)


func _draw_tendril(origin: Vector2, dir: Vector2, t: float, phase: float, brightness: float) -> void:
	var base_length: float = 55.0
	var color := Color(1.0, 1.0, 1.0, 0.5 * brightness)
	var glow := Color(0.5, 0.92, 1.0, 0.12 * brightness)

	# Build an organic tendril using wobbly points
	var pts := PackedVector2Array()
	var glow_pts := PackedVector2Array()
	var segments: int = 12

	# Perpendicular direction for sideways wobble
	var perp := Vector2(-dir.y, dir.x)

	for s in range(segments + 1):
		var frac: float = float(s) / float(segments)
		var dist: float = 18.0 + frac * base_length

		# Wobble sideways (organic curve)
		var wobble: float = sin(frac * TAU * 1.5 + t * 1.8 + phase) * 6.0 * frac
		# Slight length breathing
		var breath: float = 1.0 + sin(t * 1.2 + phase) * 0.08

		var pt: Vector2 = origin + dir * dist * breath + perp * wobble
		pts.append(pt)
		glow_pts.append(pt)

	# Taper: draw main line then glow
	if pts.size() > 1:
		draw_polyline(glow_pts, glow, 6.0, true)
		draw_polyline(pts, color, 2.5, true)

	# Tip glow dot
	if pts.size() > 0:
		var tip: Vector2 = pts[pts.size() - 1]
		var tip_pulse: float = 0.5 + sin(t * 2.2 + phase) * 0.3
		draw_circle(tip, 4.0 * tip_pulse, Color(0.5, 0.92, 1.0, 0.25 * brightness))
		draw_circle(tip, 2.0 * tip_pulse, Color(0.85, 0.95, 1.0, 0.4 * brightness))
