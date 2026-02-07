extends Node2D

## Pictogram: Lightnode interaction — looping cycle of approach, rotate, light up.

var _fish_tex: Texture2D
var _node_tex: Texture2D
var _fish_size := Vector2(24, 24)
var _node_size := Vector2(28, 28)

const CYCLE_DURATION: float = 4.0  # seconds for full loop
# Phase timings within cycle:
const APPROACH_END: float = 1.2    # fish slides in
const ROTATE_END: float = 2.0     # lightnode rotates
const GLOW_END: float = 3.2       # lightnode glows brightly
# 3.2 - 4.0 = fade/reset

var _dim_color := Color(0.015, 0.022, 0.171, 0.6)
var _lit_color := Color(0.953, 0.027, 0.043, 1.0)
var _fish_color := Color(0.012, 0.012, 0.804, 0.9)
var _glow_color := Color(0.953, 0.027, 0.043, 0.2)


func _ready() -> void:
	_fish_tex = preload("res://assets/art/ictio/carp/ictio-1.png")
	_node_tex = preload("res://assets/art/lightnodes/lightnode-01.png")
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cycle_t := fmod(t, CYCLE_DURATION)

	# Lightnode position (right of center)
	var node_pos := Vector2(20, 0)

	# --- Lightnode ---
	var node_rotation: float = 0.0
	var node_color: Color = _dim_color
	var show_glow: bool = false
	var glow_strength: float = 0.0

	if cycle_t < APPROACH_END:
		# Dim, waiting
		node_color = _dim_color
	elif cycle_t < ROTATE_END:
		# Rotating phase — rotate 45 degrees
		var rot_progress: float = clampf((cycle_t - APPROACH_END) / (ROTATE_END - APPROACH_END), 0.0, 1.0)
		# Ease out
		rot_progress = 1.0 - (1.0 - rot_progress) * (1.0 - rot_progress)
		node_rotation = deg_to_rad(45.0) * rot_progress
		# Start transitioning color
		node_color = _dim_color.lerp(_lit_color, rot_progress * 0.5)
	elif cycle_t < GLOW_END:
		# Glowing phase
		var glow_progress: float = clampf((cycle_t - ROTATE_END) / (GLOW_END - ROTATE_END), 0.0, 1.0)
		node_rotation = deg_to_rad(45.0)
		node_color = _dim_color.lerp(_lit_color, 0.5 + glow_progress * 0.5)
		show_glow = true
		glow_strength = glow_progress
	else:
		# Fade/reset
		var fade_progress: float = clampf((cycle_t - GLOW_END) / (CYCLE_DURATION - GLOW_END), 0.0, 1.0)
		node_rotation = deg_to_rad(45.0) * (1.0 - fade_progress)
		node_color = _lit_color.lerp(_dim_color, fade_progress)
		show_glow = true
		glow_strength = 1.0 - fade_progress

	# Draw glow halo behind lightnode
	if show_glow and glow_strength > 0.01:
		var pulse: float = 1.0 + sin(t * 1.8) * 0.1
		draw_circle(node_pos, 22.0 * pulse, Color(_glow_color.r, _glow_color.g, _glow_color.b, _glow_color.a * glow_strength))
		draw_circle(node_pos, 14.0 * pulse, Color(_lit_color.r, _lit_color.g, _lit_color.b, 0.15 * glow_strength))

	# Draw lightnode icon (rotated)
	if _node_tex:
		draw_set_transform(node_pos, node_rotation, Vector2.ONE)
		var rect := Rect2(-_node_size * 0.5, _node_size)
		draw_texture_rect(_node_tex, rect, false, node_color)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)  # reset transform

	# --- Fish approaching ---
	var fish_pos := Vector2(-70, 0)  # start far left

	if cycle_t < APPROACH_END:
		# Slide in from left toward lightnode
		var approach_progress: float = clampf(cycle_t / APPROACH_END, 0.0, 1.0)
		# Ease out
		approach_progress = 1.0 - (1.0 - approach_progress) * (1.0 - approach_progress)
		fish_pos = Vector2(-70, 0).lerp(node_pos + Vector2(-30, 0), approach_progress)
	elif cycle_t < ROTATE_END:
		# Hold near lightnode
		fish_pos = node_pos + Vector2(-30, 0)
	elif cycle_t < GLOW_END:
		# Fish near lightnode, slight bob
		fish_pos = node_pos + Vector2(-30, sin(t * 1.5) * 2.0)
	else:
		# Fade out (fish retreats slightly)
		var fade_progress: float = clampf((cycle_t - GLOW_END) / (CYCLE_DURATION - GLOW_END), 0.0, 1.0)
		fish_pos = (node_pos + Vector2(-30, 0)).lerp(Vector2(-70, 0), fade_progress)

	# Fish alpha (fade at reset)
	var fish_alpha: float = 1.0
	if cycle_t > GLOW_END:
		fish_alpha = 1.0 - clampf((cycle_t - GLOW_END) / (CYCLE_DURATION - GLOW_END), 0.0, 1.0)
	elif cycle_t < 0.3:
		fish_alpha = clampf(cycle_t / 0.3, 0.0, 1.0)

	# Correct speed halo around fish (shows it's at right speed)
	if cycle_t > 0.3 and cycle_t < GLOW_END:
		var halo_pulse: float = 1.0 + sin(t * 1.6) * 0.12
		draw_circle(fish_pos, 16.0 * halo_pulse, Color(0.5, 0.92, 1.0, 0.1 * fish_alpha))

	if _fish_tex:
		var rect := Rect2(fish_pos - _fish_size * 0.5, _fish_size)
		var col := Color(_fish_color.r, _fish_color.g, _fish_color.b, _fish_color.a * fish_alpha)
		draw_texture_rect(_fish_tex, rect, false, col)
