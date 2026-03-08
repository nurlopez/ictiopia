extends Node2D

## Pictogram: Speed moderation — three tiers: too slow (dim), correct (bright), too fast (red).

var _fish_tex: Texture2D
var _fish_size := Vector2(24, 24)

# Colors matching game palette
var _slow_color := Color(0.027, 0.063, 0.455, 0.5)
var _good_color := Color(0.012, 0.012, 0.804, 0.9)
var _fast_color := Color(0.953, 0.027, 0.043, 0.7)
var _glow_good := Color(0.5, 0.92, 1.0, 0.25)
var _dim_trail := Color(0.027, 0.063, 0.455, 0.25)
var _red_trail := Color(0.953, 0.027, 0.043, 0.3)
var _time_offset: float = 0.0


func reset_animation() -> void:
	_time_offset = Time.get_ticks_msec() / 1000.0


func _ready() -> void:
	_fish_tex = preload("res://assets/art/ictio/carp/ictio-1.png")
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := (Time.get_ticks_msec() / 1000.0) - _time_offset

	# Three rows, each offset vertically
	var row_spacing: float = 50.0
	var row_y_start: float = -row_spacing  # top row above center

	# Row 1: Too slow (dim, barely moving)
	_draw_speed_row(Vector2(0, row_y_start), t, 0.15, _slow_color, _dim_trail, false)

	# Row 2: Just right (bright, moderate trail, glow halo)
	_draw_speed_row(Vector2(0, row_y_start + row_spacing), t, 0.5, _good_color, _good_color * 0.5, true)

	# Row 3: Too fast (red, chaotic trail)
	_draw_speed_row(Vector2(0, row_y_start + row_spacing * 2.0), t, 1.2, _fast_color, _red_trail, false)


func _draw_speed_row(center: Vector2, t: float, speed_factor: float, fish_color: Color, trail_color: Color, is_correct: bool) -> void:
	var row_width: float = 120.0

	# Fish moves back and forth at given speed
	var cycle: float = fmod(t * speed_factor, 2.0)
	var fish_x: float
	if cycle < 1.0:
		fish_x = lerpf(-row_width * 0.4, row_width * 0.4, cycle)
	else:
		fish_x = lerpf(row_width * 0.4, -row_width * 0.4, cycle - 1.0)

	var fish_pos := center + Vector2(fish_x, 0)

	# Correct row: pulsing halo behind fish
	if is_correct:
		var pulse: float = 1.0 + sin(t * 1.6) * 0.15
		draw_circle(fish_pos, 22.0 * pulse, Color(_glow_good.r, _glow_good.g, _glow_good.b, 0.08))
		draw_circle(fish_pos, 14.0 * pulse, Color(_glow_good.r, _glow_good.g, _glow_good.b, 0.18))

	# Trailing dots behind fish (more dots = faster)
	var num_dots: int = int(clampf(speed_factor * 6.0, 1, 8))
	for i in range(num_dots):
		var frac: float = float(i + 1) / float(num_dots + 1)
		var trail_offset: float = frac * 30.0 * speed_factor

		# Trail behind the fish (opposite to movement direction)
		var dir_sign: float = 1.0 if fmod(t * speed_factor, 2.0) < 1.0 else -1.0
		var dot_pos := fish_pos - Vector2(dir_sign * trail_offset, 0)

		# Wobble for fast speed
		if speed_factor > 0.8:
			dot_pos.y += sin(t * 6.0 + float(i) * 2.1) * 3.0 * speed_factor

		var dot_alpha: float = trail_color.a * (1.0 - frac * 0.7)
		var dot_radius: float = (3.0 - frac * 1.5) * (0.8 + sin(t * 2.0 + float(i)) * 0.2)
		draw_circle(dot_pos, dot_radius, Color(trail_color.r, trail_color.g, trail_color.b, dot_alpha))

	# Draw fish
	if _fish_tex:
		var rect := Rect2(fish_pos - _fish_size * 0.5, _fish_size)
		# Flip based on direction
		if fmod(t * speed_factor, 2.0) >= 1.0:
			rect.position.x += rect.size.x
			rect.size.x = -rect.size.x
		draw_texture_rect(_fish_tex, rect, false, fish_color)

	# Wrong rows: subtle X or dimming indicator
	if not is_correct:
		# Draw faint "wrong" indicator — a small dimming ring
		var dim_pulse: float = 0.3 + sin(t * 2.5) * 0.15
		draw_circle(center + Vector2(row_width * 0.48, 0), 5.0, Color(fish_color.r, fish_color.g, fish_color.b, dim_pulse * 0.3))
