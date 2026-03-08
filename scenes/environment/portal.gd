extends Area2D

## Bioluminescent portal — membrane-like rings that pulse when open.
## Appears outside the chambers so the player navigates the lit world to reach it.

@export var start_hidden: bool = true
@export var accepts_player: bool = false
@export var on_enter_fade_time: float = 0.6
@export var open_sound: AudioStream
@export var enter_sound: AudioStream

# Visual settings
@export var ring_color: Color = Color(0.5, 0.92, 1.0, 0.55)
@export var core_color: Color = Color(0.85, 0.95, 1.0, 0.4)
@export var ring_count: int = 2
@export var base_radius: float = 12.0
@export var ring_spacing: float = 10.0
@export var ring_width: float = 1.0

# Organic wobble controls
@export var wobble_strength: float = 1 # how “wavy” the membrane is
@export var wobble_speed: float = 0.8 # how fast it flows
@export var wobble_freq_1: float = 3.0 # big undulations
@export var wobble_freq_2: float = 7.0 # small ripples
@export var arc_steps: int = 36 # quality vs cost

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var point_light: PointLight2D = $PointLight2D

var _visible_amount: float = 0.0 # 0 = hidden, 1 = fully visible
var _is_open: bool = false
var _entered: bool = false


func _ready() -> void:
	if not is_connected("body_entered", Callable(self , "_on_body_entered")):
		connect("body_entered", Callable(self , "_on_body_entered"))

	if start_hidden:
		_visible_amount = 0.0
		shape.set_deferred("disabled", true)
		accepts_player = false
	else:
		_visible_amount = 1.0
		_is_open = true

	set_process(true)


func _process(_delta: float) -> void:
	if _is_open or _visible_amount > 0.01:
		queue_redraw()

	# Gentle living light pulse (feels like pressure, not a lamp)
	if point_light and (_is_open or _visible_amount > 0.01):
		var t := float(Time.get_ticks_msec()) / 1000.0
		var target := (0.42 + sin(t * 1.15) * 0.14) * _visible_amount
		point_light.energy = lerp(point_light.energy, target, 0.08)


func open_portal() -> void:
	accepts_player = true
	_is_open = true
	shape.set_deferred("disabled", false)

	# Fade in
	var tween := create_tween()
	tween.tween_property(self , "_visible_amount", 1.0, 0.5).set_ease(Tween.EASE_OUT)

	if point_light:
		var light_tween := create_tween()
		light_tween.tween_property(point_light, "energy", 0.55, 0.5)

	if open_sound:
		audio.stream = open_sound
		audio.volume_db = -6.0
		audio.play()


func _on_body_entered(body: Node) -> void:
	if not accepts_player or _entered:
		return
	if body == null or body.name != "Ictio":
		return

	_entered = true

	if enter_sound:
		audio.stream = enter_sound
		audio.volume_db = -6.0
		audio.play()

	# Fade out
	var tween := create_tween()
	tween.tween_property(self , "_visible_amount", 0.0, on_enter_fade_time)
	if point_light:
		tween.parallel().tween_property(point_light, "energy", 0.0, on_enter_fade_time)
	await tween.finished

	get_tree().reload_current_scene()


# --- Organic membrane helpers -------------------------------------------------

func _membrane_radius(base: float, angle: float, t: float, phase: float) -> float:
	# Two-layer wobble: big slow waves + smaller ripples
	var n := sin(angle * wobble_freq_1 + t * wobble_speed + phase) * 0.60
	n += sin(angle * wobble_freq_2 - t * (wobble_speed * 0.55) + phase * 2.1) * 0.35
	return base * (1.0 + n * wobble_strength)


func _draw_membrane_arc(radius: float, start_angle: float, end_angle: float, col: Color, width: float, phase: float, t: float) -> void:
	var pts := PackedVector2Array()
	var steps: int = max(8, arc_steps)
	for s in range(steps + 1):
		var a: float = lerp(start_angle, end_angle, float(s) / float(steps))
		var r := _membrane_radius(radius, a, t, phase)
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, width, true)


func _draw() -> void:
	if _visible_amount < 0.01:
		return

	var t := float(Time.get_ticks_msec()) / 1000.0

	# Core nucleus — soft, larger, slightly wobbling (less “orb”, more “living gel”)
	var core_alpha: float = core_color.a * _visible_amount
	var wobble := Vector2(
		sin(t * 0.65) * 2.0,
		cos(t * 0.85) * 1.6
	)

	var core_pulse: float = 1.0 + sin(t * 1.2) * 0.10
	var core_r: float = base_radius * 0.95 * core_pulse

	var c1 := Color(core_color.r, core_color.g, core_color.b, core_alpha * 0.22)
	var c2 := Color(core_color.r, core_color.g, core_color.b, core_alpha * 0.10)
	draw_circle(wobble, core_r, c1)
	draw_circle(-wobble * 0.6, core_r * 0.75, c2)

	# Membrane arcs — wobbly polylines + drift (no mechanical rotation)
	for i in range(ring_count):
		var fi: float = float(i)
		var base_r: float = base_radius + ring_spacing * (fi + 1.0)

		# Breathing pulse per layer
		var pulse: float = 1.0 + sin(t * (0.95 + fi * 0.25) + fi * 1.7) * 0.10
		var radius := base_r * pulse

		# Organic partial arc: longer for outer layer
		var arc_length: float = TAU * (0.72 + fi * 0.10)

		# Drift instead of rotation (feels like currents)
		var drift := sin(t * 0.35 + fi * 2.1) * 0.7
		var start_angle: float = fi * TAU / 4.0 + drift
		var end_angle: float = start_angle + arc_length

		# Alpha & thickness
		var alpha: float = ring_color.a * _visible_amount * (1.0 - fi * 0.18)
		var col := Color(ring_color.r, ring_color.g, ring_color.b, alpha)

		var width: float = ring_width * (0.85 - fi * 0.20) * (0.9 + sin(t * 1.05 + fi) * 0.10)

		# Main membrane
		_draw_membrane_arc(radius, start_angle, end_angle, col, width, fi * 10.0 + 1.3, t)

		# Soft outer bloom (fake blur)
		var glow_col := Color(col.r, col.g, col.b, alpha * 0.22)
		_draw_membrane_arc(radius, start_angle, end_angle, glow_col, width + 5.0, fi * 10.0 + 9.7, t)
