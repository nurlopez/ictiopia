extends Control

## Flow glyph for speed feedback (slow/ok/fast).

@export var slow_color: Color = Color(0.35, 0.75, 0.95, 0.85)
@export var ok_color: Color = Color(0.45, 1.0, 0.8, 0.95)
@export var fast_color: Color = Color(0.95, 0.5, 0.7, 0.95)
@export var dot_radius: float = 5.0
@export var spacing: float = 14.0

var _speed: float = 0.0
var _min_speed: float = 40.0
var _max_speed: float = 160.0


func _ready() -> void:
	set_process(true)


func set_speed(speed: float, min_speed: float, max_speed: float) -> void:
	_speed = max(speed, 0.0)
	_min_speed = min_speed
	_max_speed = max_speed
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var color: Color
	if _speed < _min_speed:
		color = slow_color
	elif _speed > _max_speed:
		color = fast_color
	else:
		color = ok_color

	# Motion phase for a gentle flow feel
	var t := float(Time.get_ticks_msec()) / 1000.0
	var speed_norm := clampf(_speed / maxf(_max_speed, 1.0), 0.0, 1.0)
	var phase := t * (1.2 + speed_norm * 1.5)

	var offsets := [
		Vector2(-spacing, 0.0),
		Vector2(0.0, -spacing * 0.35),
		Vector2(spacing, 0.0)
	]

	# Soft trail line
	var trail_color := color
	trail_color.a *= 0.35
	draw_line(center + offsets[0], center + offsets[2], trail_color, 2.0, true)

	# Draw dots with slight breathing
	for i in range(offsets.size()):
		var wobble: float = sin(phase + float(i) * 1.4) * 2.0
		var pos: Vector2 = center + offsets[i] + Vector2(0.0, wobble)
		draw_circle(pos, dot_radius, color)
		var glow := color
		glow.a *= 0.28
		draw_circle(pos, dot_radius + 3.5, glow)
