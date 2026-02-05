extends Control

## Lightnode progress glyph (filled dots).

@export var node_radius: float = 5.0
@export var spacing: float = 18.0
@export var inactive_color: Color = Color(0.2, 0.45, 0.6, 0.45)
@export var active_color: Color = Color(0.6, 0.95, 1.0, 0.95)

var _total: int = 0
var _fixed: int = 0


func _ready() -> void:
	set_process(true)


func set_progress(total: int, fixed: int) -> void:
	_total = max(total, 0)
	_fixed = clamp(fixed, 0, _total)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _total <= 0:
		return

	var width := float(_total - 1) * spacing
	var start := size * 0.5 - Vector2(width * 0.5, 0.0)

	for i in range(_total):
		var pos := start + Vector2(float(i) * spacing, 0.0)
		var is_active := i < _fixed
		var col := active_color if is_active else inactive_color
		draw_circle(pos, node_radius, col)

		if is_active:
			var glow := col
			glow.a *= 0.35
			draw_circle(pos, node_radius + 3.0, glow)
