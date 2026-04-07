extends Control

## Minimal arc gauge — shows current speed relative to the goldilocks zone.
## Color-coded: deep blue (slow), bright blue (good), red (fast).

@export var gauge_radius: float = 26.0
@export var arc_width: float = 2.0
@export var marker_radius: float = 2.5

# Speed ranges (keep in sync with ictio.gd)
var _max_speed: float = 200.0
var _min_effective: float = 40.0
var _max_effective: float = 160.0

# Zone colors
const SLOW_COLOR := Color(0.027, 0.063, 0.455, 0.35)
const GOOD_COLOR := Color(0.012, 0.012, 0.804, 0.55)
const FAST_COLOR := Color(0.953, 0.027, 0.043, 0.35)
const MARKER_GOOD := Color(0.3, 0.3, 1.0, 0.95)
const MARKER_BAD := Color(1.0, 1.0, 1.0, 0.7)
const ZONE_GLOW := Color(0.012, 0.012, 0.804, 0.1)

var _speed: float = 0.0
var _ictio: CharacterBody2D

# Arc geometry: 270-degree sweep starting from bottom-left
const ARC_START: float = PI * 0.75
const ARC_SWEEP: float = PI * 1.5
const ARC_STEPS: int = 48


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	_ictio = get_node_or_null("%Ictio")
	if _ictio:
		_max_speed = _ictio.max_speed
		_min_effective = _ictio.min_effective_speed
		_max_effective = _ictio.max_effective_speed


func _process(_delta: float) -> void:
	if _ictio and is_instance_valid(_ictio):
		var new_speed: float = _ictio.velocity.length()
		if absf(new_speed - _speed) > 0.5:
			_speed = new_speed
			queue_redraw()


func _draw() -> void:
	var center := Vector2(gauge_radius + 4.0, size.y - gauge_radius - 4.0)
	var min_t: float = _min_effective / _max_speed
	var max_t: float = _max_effective / _max_speed

	# Background arc — color-coded segments
	for i in range(ARC_STEPS):
		var t0: float = float(i) / float(ARC_STEPS)
		var t1: float = float(i + 1) / float(ARC_STEPS)
		var mid_t: float = (t0 + t1) * 0.5

		var col: Color
		if mid_t < min_t:
			col = SLOW_COLOR
		elif mid_t > max_t:
			col = FAST_COLOR
		else:
			col = GOOD_COLOR

		var a0: float = ARC_START + t0 * ARC_SWEEP
		var a1: float = ARC_START + t1 * ARC_SWEEP
		var p0 := center + Vector2(cos(a0), sin(a0)) * gauge_radius
		var p1 := center + Vector2(cos(a1), sin(a1)) * gauge_radius
		draw_line(p0, p1, col, arc_width, true)

	# Goldilocks glow when in zone
	var in_zone: bool = _speed >= _min_effective and _speed <= _max_effective
	if in_zone and _speed > 5.0:
		var t: float = float(Time.get_ticks_msec()) / 1000.0
		var pulse: float = 0.7 + sin(t * 2.0) * 0.3
		var glow_a: float = ARC_START + min_t * ARC_SWEEP
		var glow_b: float = ARC_START + max_t * ARC_SWEEP
		var glow_steps: int = 16
		for i in range(glow_steps):
			var s0: float = float(i) / float(glow_steps)
			var s1: float = float(i + 1) / float(glow_steps)
			var a0: float = lerpf(glow_a, glow_b, s0)
			var a1: float = lerpf(glow_a, glow_b, s1)
			var p0 := center + Vector2(cos(a0), sin(a0)) * gauge_radius
			var p1 := center + Vector2(cos(a1), sin(a1)) * gauge_radius
			var gcol := Color(ZONE_GLOW.r, ZONE_GLOW.g, ZONE_GLOW.b, ZONE_GLOW.a * pulse)
			draw_line(p0, p1, gcol, arc_width + 5.0, true)

	# Speed marker dot
	if _speed > 1.0:
		var speed_t: float = clampf(_speed / _max_speed, 0.0, 1.0)
		var marker_angle: float = ARC_START + speed_t * ARC_SWEEP
		var marker_pos := center + Vector2(cos(marker_angle), sin(marker_angle)) * gauge_radius

		var m_col: Color = MARKER_GOOD if in_zone else MARKER_BAD
		draw_circle(marker_pos, marker_radius + 2.0, Color(m_col.r, m_col.g, m_col.b, 0.15))
		draw_circle(marker_pos, marker_radius, m_col)
