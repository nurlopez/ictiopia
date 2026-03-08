extends Control

## Sequential carousel level intro — one pictogram at a time, player-paced.
## Each step gets full-screen attention with progress dots and advance hint.

signal intro_dismissed

@export var level_number: int = 1
@export var enter_duration: float = 0.4
@export var min_display_time: float = 1.2
@export var slide_duration: float = 0.4
@export var dismiss_fade: float = 0.5

enum State { ENTERING, SHOWING, READY_TO_ADVANCE, TRANSITIONING, DISMISSED }

var _state: State = State.ENTERING
var _current_step: int = 0
var _step_nodes: Array[Node2D] = []
var _state_entered_at: float = 0.0
var _dots_layer: Control

const CENTER := Vector2(640, 320)
const OFFSCREEN_LEFT := Vector2(-300, 320)
const OFFSCREEN_RIGHT := Vector2(1580, 320)
const STEP_SCALE := Vector2(2.2, 2.2)
const DOTS_Y: float = 640.0


func _ready() -> void:
	# Collect step children
	for child in get_children():
		if child is Node2D and child.name.begins_with("Step"):
			_step_nodes.append(child)
			child.modulate.a = 0.0
			child.scale = STEP_SCALE
			child.position = OFFSCREEN_RIGHT

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Dots layer renders on top of overlay and steps
	_dots_layer = Control.new()
	_dots_layer.name = "DotsLayer"
	_dots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dots_layer)
	_dots_layer.draw.connect(_draw_dots)

	# Start the first step
	if _step_nodes.size() > 0:
		_enter_step(0)


func _process(_delta: float) -> void:
	if _state == State.DISMISSED:
		return

	# Transition from SHOWING to READY_TO_ADVANCE after min display time
	if _state == State.SHOWING:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - _state_entered_at
		if elapsed >= min_display_time:
			_set_state(State.READY_TO_ADVANCE)

	if _dots_layer:
		_dots_layer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.READY_TO_ADVANCE:
		return

	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	elif event is InputEventJoypadButton and event.pressed:
		pressed = true

	if pressed:
		get_viewport().set_input_as_handled()
		if _current_step >= _step_nodes.size() - 1:
			_dismiss()
		else:
			_advance()


func _enter_step(index: int) -> void:
	_current_step = index
	_set_state(State.ENTERING)

	var step := _step_nodes[index]
	step.position = CENTER if index == 0 else OFFSCREEN_RIGHT
	step.modulate.a = 0.0

	# Reset animation so player sees full cycle
	if step.has_method("reset_animation"):
		step.reset_animation()

	if index == 0:
		# First step: fade in at center
		var tween := create_tween()
		tween.tween_property(step, "modulate:a", 1.0, enter_duration).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_on_enter_complete)
	else:
		# Subsequent steps: slide in from right (handled by _advance)
		step.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(step, "position", CENTER, slide_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(_on_enter_complete)


func _advance() -> void:
	_set_state(State.TRANSITIONING)

	var current := _step_nodes[_current_step]
	var next_index := _current_step + 1
	var next := _step_nodes[next_index]

	# Prepare next step
	next.position = OFFSCREEN_RIGHT
	next.modulate.a = 1.0
	if next.has_method("reset_animation"):
		next.reset_animation()

	# Parallel tweens: current slides left, next slides in from right
	var tween := create_tween().set_parallel(true)
	tween.tween_property(current, "position", OFFSCREEN_LEFT, slide_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(current, "modulate:a", 0.0, slide_duration * 0.8)
	tween.tween_property(next, "position", CENTER, slide_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.chain().tween_callback(func():
		_current_step = next_index
		_on_enter_complete()
	)


func _dismiss() -> void:
	_set_state(State.DISMISSED)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, dismiss_fade).set_ease(Tween.EASE_IN)
	await tween.finished
	intro_dismissed.emit()
	queue_free()


func _on_enter_complete() -> void:
	_set_state(State.SHOWING)


func _set_state(new_state: State) -> void:
	_state = new_state
	_state_entered_at = Time.get_ticks_msec() / 1000.0


func _draw_dots() -> void:
	if _state == State.DISMISSED:
		return

	var t := Time.get_ticks_msec() / 1000.0
	var total_steps := _step_nodes.size()
	if total_steps == 0:
		return

	# --- Progress dots at bottom ---
	var dot_spacing: float = 30.0
	var dots_start_x: float = _dots_layer.size.x * 0.5 - (float(total_steps - 1) * dot_spacing) / 2.0

	for i in range(total_steps):
		var dot_pos := Vector2(dots_start_x + float(i) * dot_spacing, DOTS_Y)

		if i < _current_step:
			# Completed: warm white with glow
			_dots_layer.draw_circle(dot_pos, 12.0, Color(1.0, 0.95, 0.85, 0.12))
			_dots_layer.draw_circle(dot_pos, 6.0, Color(1.0, 0.97, 0.9, 0.9))
		elif i == _current_step:
			# Current: bright white pulsing
			var pulse: float = 1.0 + sin(t * 2.0) * 0.2
			_dots_layer.draw_circle(dot_pos, 14.0 * pulse, Color(1.0, 0.95, 0.85, 0.15))
			_dots_layer.draw_circle(dot_pos, 8.0 * pulse, Color(1.0, 0.97, 0.9, 0.3))
			_dots_layer.draw_circle(dot_pos, 6.0, Color(1.0, 1.0, 1.0, 1.0))
		else:
			# Future: visible warm white, subdued
			_dots_layer.draw_circle(dot_pos, 8.0, Color(1.0, 0.95, 0.85, 0.08))
			_dots_layer.draw_circle(dot_pos, 5.0, Color(1.0, 0.97, 0.9, 0.45))

	# --- Advance hint: breathing ring + chevron when ready ---
	if _state == State.READY_TO_ADVANCE:
		var hint_alpha := clampf((t - _state_entered_at) / 0.5, 0.0, 1.0)
		var current_dot_pos := Vector2(
			dots_start_x + float(_current_step) * dot_spacing, DOTS_Y
		)

		# Breathing ring around current dot
		var ring_pulse: float = 1.0 + sin(t * 1.8) * 0.2
		var ring_alpha: float = hint_alpha * (0.3 + sin(t * 1.8) * 0.15)
		_dots_layer.draw_arc(current_dot_pos, 14.0 * ring_pulse, 0, TAU, 32,
			Color(1.0, 0.97, 0.9, ring_alpha), 1.5, true)

		# Small chevron to the right of current dot
		var chevron_x: float = current_dot_pos.x + 18.0
		var chevron_y: float = current_dot_pos.y
		var bounce: float = sin(t * 2.5) * 2.0
		var chevron_color := Color(1.0, 0.97, 0.9, hint_alpha * 0.6)

		var chevron_pts := PackedVector2Array([
			Vector2(chevron_x + bounce, chevron_y - 5.0),
			Vector2(chevron_x + 5.0 + bounce, chevron_y),
			Vector2(chevron_x + bounce, chevron_y + 5.0),
		])
		_dots_layer.draw_polyline(chevron_pts, chevron_color, 1.5, true)
