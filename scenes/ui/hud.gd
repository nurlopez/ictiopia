extends Control

## Minimal HUD — lightnode progress only.
## Stress and speed are communicated through environmental feedback
## (membrane walls, circuit network, soundscape).

@export var update_rate: float = 0.15

@onready var node_progress := get_node_or_null("%NodeProgress")

var _time_accum: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum < update_rate:
		return
	_time_accum = 0.0

	if node_progress and node_progress.has_method("update_progress"):
		node_progress.update_progress()
