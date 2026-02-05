extends Control

## Icon-only HUD for non-verbal feedback.
## Feeds stress, speed, and lightnode progress into pictogram widgets.

@export var min_speed: float = 40.0
@export var max_speed: float = 160.0
@export var update_rate: float = 0.08

@onready var stress_ring := get_node_or_null("%StressRing")
@onready var speed_glyph := get_node_or_null("%SpeedGlyph")
@onready var node_progress := get_node_or_null("%NodeProgress")

var _ictio: CharacterBody2D
var _nervous: NervousSystem
var _time_accum: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_find_player_and_systems()
	_sync_speed_ranges_from_lightnodes()
	set_process(true)


func _find_player_and_systems() -> void:
	_ictio = get_node_or_null("%Ictio") as CharacterBody2D
	_nervous = get_node_or_null("%NervousSystem") as NervousSystem


func _sync_speed_ranges_from_lightnodes() -> void:
	# If any lightnode exists, use its tuning to keep HUD in sync.
	var nodes := get_tree().get_nodes_in_group("lightnodes")
	if nodes.size() == 0:
		return
	var ln := nodes[0]
	if ln and ln.has_method("get"):
		var minv = ln.get("min_effective_speed")
		var maxv = ln.get("max_effective_speed")
		if typeof(minv) == TYPE_FLOAT or typeof(minv) == TYPE_INT:
			min_speed = float(minv)
		if typeof(maxv) == TYPE_FLOAT or typeof(maxv) == TYPE_INT:
			max_speed = float(maxv)


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum < update_rate:
		return
	_time_accum = 0.0

	var speed: float = 0.0
	if _ictio:
		speed = _ictio.velocity.length()

	var stress: float = 0.0
	if _nervous:
		stress = _nervous.get_stress_level()

	if stress_ring and stress_ring.has_method("set_stress"):
		stress_ring.set_stress(stress)

	if speed_glyph and speed_glyph.has_method("set_speed"):
		speed_glyph.set_speed(speed, min_speed, max_speed)

	# Count lightnodes and fixed ones
	var total := 0
	var fixed := 0
	var nodes := get_tree().get_nodes_in_group("lightnodes")
	for n in nodes:
		if n == null:
			continue
		total += 1
		if n.get("_is_fixed"):
			fixed += 1

	if node_progress and node_progress.has_method("set_progress"):
		node_progress.set_progress(total, fixed)
