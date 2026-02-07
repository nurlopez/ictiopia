extends Control

## Visual-only level intro — pictogram instructions with staggered reveal.
## No text. Teaches mechanics through animated pictograms.

signal intro_dismissed

@export var level_number: int = 1
@export var reveal_delay: float = 0.8   # seconds between each pictogram appearing
@export var reveal_fade: float = 0.6    # fade-in duration per pictogram
@export var dismiss_fade: float = 0.5   # fade-out when dismissed

var _intro_start_time: float = 0.0
var _intro_active: bool = true
var _step_nodes: Array[Node2D] = []


func _ready() -> void:
	_intro_start_time = Time.get_ticks_msec() / 1000.0

	# Collect pictogram step children (Step1, Step2, etc.)
	for child in get_children():
		if child is Node2D and child.name.begins_with("Step"):
			_step_nodes.append(child)
			child.modulate.a = 0.0

	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not _intro_active:
		return

	# Update step alphas based on staggered timing
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _intro_start_time
	for i in range(_step_nodes.size()):
		var step_start: float = float(i) * reveal_delay
		if elapsed < step_start:
			_step_nodes[i].modulate.a = 0.0
		else:
			var progress: float = clampf((elapsed - step_start) / reveal_fade, 0.0, 1.0)
			# Ease out quad
			_step_nodes[i].modulate.a = 1.0 - (1.0 - progress) * (1.0 - progress)

	# Redraw level indicator + dismiss hint
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _intro_active:
		return
	if event is InputEventKey and event.pressed:
		_dismiss()
	elif event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventJoypadButton and event.pressed:
		_dismiss()


func _dismiss() -> void:
	if not _intro_active:
		return
	_intro_active = false

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, dismiss_fade).set_ease(Tween.EASE_IN)
	await tween.finished
	intro_dismissed.emit()
	queue_free()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0

	# --- Level indicator: N pulsing orbs at top center ---
	var indicator_y: float = 60.0
	var indicator_center_x: float = size.x * 0.5
	var orb_spacing: float = 30.0
	var start_x: float = indicator_center_x - (float(level_number - 1) * orb_spacing) / 2.0

	for i in range(level_number):
		var pos := Vector2(start_x + float(i) * orb_spacing, indicator_y)
		var pulse: float = 1.0 + sin(t * 1.4 + float(i) * 0.8) * 0.15
		var radius: float = 8.0 * pulse

		# Outer glow layers
		draw_circle(pos, radius * 3.0, Color(0.012, 0.012, 0.804, 0.06))
		draw_circle(pos, radius * 2.0, Color(0.012, 0.012, 0.804, 0.12))
		# Core orb
		draw_circle(pos, radius, Color(0.5, 0.92, 1.0, 0.7))

	# --- Dismiss hint: pulsing orb at bottom center ---
	var elapsed: float = t - _intro_start_time
	# Only show after all pictograms have revealed
	var show_after: float = float(_step_nodes.size()) * reveal_delay + reveal_fade
	if elapsed > show_after:
		var hint_alpha: float = clampf((elapsed - show_after) / 0.8, 0.0, 1.0)
		var hint_pos := Vector2(size.x * 0.5, size.y - 50.0)
		var hint_pulse: float = 0.5 + sin(t * 1.8) * 0.3
		var base_alpha: float = hint_alpha * hint_pulse

		# Soft pulsing glow
		draw_circle(hint_pos, 14.0, Color(0.5, 0.92, 1.0, base_alpha * 0.08))
		draw_circle(hint_pos, 8.0, Color(0.5, 0.92, 1.0, base_alpha * 0.2))
		draw_circle(hint_pos, 4.0, Color(0.85, 0.95, 1.0, base_alpha * 0.5))
