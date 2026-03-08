extends Node2D

## Pictogram: Portal completion — three lit lightnodes + open portal + fish enters.

var _fish_tex: Texture2D
var _node_tex: Texture2D
var _fish_size := Vector2(20, 20)
var _node_size := Vector2(20, 20)

# Portal visual settings (matching portal.gd)
var ring_color := Color(0.5, 0.92, 1.0, 0.55)
var core_color := Color(0.85, 0.95, 1.0, 0.4)
var wobble_strength: float = 1.0
var wobble_speed: float = 0.8
var wobble_freq_1: float = 3.0
var wobble_freq_2: float = 7.0

var _lit_color := Color(0.953, 0.027, 0.043, 1.0)
var _glow_color := Color(0.953, 0.027, 0.043, 0.2)
var _fish_color := Color(0.012, 0.012, 0.804, 0.9)
var _time_offset: float = 0.0

const CYCLE_DURATION: float = 5.0
const NODES_LIT_END: float = 1.5    # lightnodes light up
const PORTAL_OPEN_END: float = 2.5  # portal appears
const FISH_ENTER_END: float = 4.0   # fish swims into portal
# 4.0 - 5.0 = reset


func reset_animation() -> void:
	_time_offset = Time.get_ticks_msec() / 1000.0


func _ready() -> void:
	_fish_tex = preload("res://assets/art/ictio/carp/ictio-1.png")
	_node_tex = preload("res://assets/art/lightnodes/lightnode-01.png")
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := (Time.get_ticks_msec() / 1000.0) - _time_offset
	var cycle_t := fmod(t, CYCLE_DURATION)

	# --- Three lit lightnodes at top ---
	var nodes_y: float = -40.0
	var node_spacing: float = 30.0
	var nodes_start_x: float = -node_spacing

	for i in range(3):
		var node_pos := Vector2(nodes_start_x + float(i) * node_spacing, nodes_y)

		# Stagger lighting up
		var light_time: float = float(i) * 0.4
		var lit_progress: float = 0.0

		if cycle_t < NODES_LIT_END:
			lit_progress = clampf((cycle_t - light_time) / 0.5, 0.0, 1.0)
		elif cycle_t < FISH_ENTER_END:
			lit_progress = 1.0
		else:
			var fade: float = clampf((cycle_t - FISH_ENTER_END) / (CYCLE_DURATION - FISH_ENTER_END), 0.0, 1.0)
			lit_progress = 1.0 - fade

		# Glow halo
		if lit_progress > 0.01:
			var pulse: float = 1.0 + sin(t * 1.8 + float(i) * 1.2) * 0.1
			draw_circle(node_pos, 14.0 * pulse, Color(_glow_color.r, _glow_color.g, _glow_color.b, _glow_color.a * lit_progress))

		# Icon
		if _node_tex:
			var color: Color = Color(0.015, 0.022, 0.171, 0.6).lerp(_lit_color, lit_progress)
			var rect := Rect2(node_pos - _node_size * 0.5, _node_size)
			draw_texture_rect(_node_tex, rect, false, color)

	# --- Portal below lightnodes ---
	var portal_pos := Vector2(0, 30.0)
	var portal_alpha: float = 0.0

	if cycle_t < NODES_LIT_END:
		portal_alpha = 0.0
	elif cycle_t < PORTAL_OPEN_END:
		portal_alpha = clampf((cycle_t - NODES_LIT_END) / (PORTAL_OPEN_END - NODES_LIT_END), 0.0, 1.0)
	elif cycle_t < FISH_ENTER_END:
		portal_alpha = 1.0
	else:
		portal_alpha = 1.0 - clampf((cycle_t - FISH_ENTER_END) / (CYCLE_DURATION - FISH_ENTER_END), 0.0, 1.0)

	if portal_alpha > 0.01:
		_draw_portal(portal_pos, t, portal_alpha)

	# --- Fish swimming toward portal ---
	var fish_alpha: float = 0.0
	var fish_pos := Vector2(-60, 30)

	if cycle_t >= PORTAL_OPEN_END and cycle_t < FISH_ENTER_END:
		var progress: float = clampf((cycle_t - PORTAL_OPEN_END) / (FISH_ENTER_END - PORTAL_OPEN_END), 0.0, 1.0)
		# Ease in-out
		progress = progress * progress * (3.0 - 2.0 * progress)
		fish_pos = Vector2(-60, 30).lerp(portal_pos, progress)
		fish_alpha = 1.0
		# Fade as entering portal
		if progress > 0.7:
			fish_alpha = 1.0 - (progress - 0.7) / 0.3
	elif cycle_t < PORTAL_OPEN_END and cycle_t >= NODES_LIT_END:
		# Fish waits off to the left, fading in
		fish_alpha = clampf((cycle_t - NODES_LIT_END) / 0.5, 0.0, 0.8)
		fish_pos = Vector2(-60, 30)

	if fish_alpha > 0.01 and _fish_tex:
		var rect := Rect2(fish_pos - _fish_size * 0.5, _fish_size)
		var col := Color(_fish_color.r, _fish_color.g, _fish_color.b, _fish_color.a * fish_alpha)
		draw_texture_rect(_fish_tex, rect, false, col)


func _draw_portal(center: Vector2, t: float, alpha: float) -> void:
	# Core nucleus (matching portal.gd style)
	var core_pulse: float = 1.0 + sin(t * 1.2) * 0.10
	var core_r: float = 8.0 * core_pulse
	var wobble := Vector2(sin(t * 0.65) * 1.5, cos(t * 0.85) * 1.2)

	var c1 := Color(core_color.r, core_color.g, core_color.b, core_color.a * alpha * 0.22)
	var c2 := Color(core_color.r, core_color.g, core_color.b, core_color.a * alpha * 0.10)
	draw_circle(center + wobble, core_r, c1)
	draw_circle(center - wobble * 0.6, core_r * 0.75, c2)

	# Membrane arcs
	for i in range(2):
		var fi: float = float(i)
		var base_r: float = 8.0 + 7.0 * (fi + 1.0)
		var pulse: float = 1.0 + sin(t * (0.95 + fi * 0.25) + fi * 1.7) * 0.10
		var radius: float = base_r * pulse
		var arc_length: float = TAU * (0.72 + fi * 0.10)
		var drift: float = sin(t * 0.35 + fi * 2.1) * 0.7
		var start_angle: float = fi * TAU / 4.0 + drift
		var end_angle: float = start_angle + arc_length

		var ring_alpha: float = ring_color.a * alpha * (1.0 - fi * 0.18)
		var col := Color(ring_color.r, ring_color.g, ring_color.b, ring_alpha)
		var width: float = 1.0 * (0.85 - fi * 0.20) * (0.9 + sin(t * 1.05 + fi) * 0.10)

		_draw_membrane_arc(center, radius, start_angle, end_angle, col, width, fi * 10.0 + 1.3, t)

		# Glow
		var glow_col := Color(col.r, col.g, col.b, ring_alpha * 0.22)
		_draw_membrane_arc(center, radius, start_angle, end_angle, glow_col, width + 5.0, fi * 10.0 + 9.7, t)


func _membrane_radius(base: float, angle: float, t: float, seed: float) -> float:
	var n := sin(angle * wobble_freq_1 + t * wobble_speed + seed) * 0.60
	n += sin(angle * wobble_freq_2 - t * (wobble_speed * 0.55) + seed * 2.1) * 0.35
	return base * (1.0 + n * wobble_strength)


func _draw_membrane_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, col: Color, width: float, seed: float, t: float) -> void:
	var pts := PackedVector2Array()
	var steps: int = 24
	for s in range(steps + 1):
		var a: float = lerpf(start_angle, end_angle, float(s) / float(steps))
		var r := _membrane_radius(radius, a, t, seed)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	if pts.size() > 1:
		draw_polyline(pts, col, width, true)
