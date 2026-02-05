extends Control

## Organic stress ring icon (no text).

@export var base_radius: float = 22.0
@export var ring_thickness: float = 4.0
@export var glow_size: float = 12.0

@export var calm_color: Color = Color(0.2, 0.85, 0.95, 0.5)   # cyan biolume
@export var stress_color: Color = Color(0.95, 0.55, 0.75, 0.8) # magenta biolume
@export var glow_color: Color = Color(0.3, 0.9, 1.0, 0.25)

var _stress: float = 0.0


func _ready() -> void:
	set_process(true)


func set_stress(value: float) -> void:
	_stress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	# Keep subtle pulse even when values change slowly.
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var t := float(Time.get_ticks_msec()) / 1000.0
	var pulse := 1.0 + sin(t * 2.2) * 0.08 * _stress
	var radius := base_radius * pulse

	var ring_color := calm_color.lerp(stress_color, _stress)
	var soft_glow := glow_color
	soft_glow.a = 0.08 + 0.18 * _stress

	# Soft halo (bioluminescent bloom)
	draw_circle(center, radius + glow_size * 0.35, soft_glow)
	draw_circle(center, radius + glow_size * 0.15, soft_glow)

	# Main ring
	draw_arc(center, radius, 0.0, TAU, 80, ring_color, ring_thickness)

	# Small pulse dot on ring
	var dot_angle := t * 1.6
	var dot_pos := center + Vector2(cos(dot_angle), sin(dot_angle)) * radius
	var dot_color := ring_color
	dot_color.a = minf(1.0, ring_color.a + 0.2)
	draw_circle(dot_pos, ring_thickness * 0.65, dot_color)
