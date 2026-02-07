extends Node2D
class_name NervousSystem

## Central coordinator for the nervous system.
## Wires player speed to stress calculation and routes stress to subsystems.

@onready var stress_manager: StressManager = $StressManager
@onready var circuit_network: CircuitNetwork = $CircuitNetwork
@onready var soundscape_manager: SoundscapeManager = $SoundscapeManager
@onready var audio_visual_sync: AudioVisualSync = $AudioVisualSync

var _ictio: CharacterBody2D


func _ready() -> void:
	# Wait a frame for scene tree to fully initialize
	await get_tree().process_frame
	_connect_ictio()
	_connect_subsystems()


func _connect_ictio() -> void:
	_ictio = get_node_or_null("%Ictio")
	if _ictio == null:
		push_warning("[NervousSystem] Could not find Ictio player node")
		return

	if _ictio.has_signal("speed_changed"):
		_ictio.speed_changed.connect(_on_player_speed_changed)


func _connect_subsystems() -> void:
	# Connect stress manager to subsystems
	if stress_manager and circuit_network:
		stress_manager.stress_changed.connect(circuit_network.on_stress_changed)

	if stress_manager and soundscape_manager:
		stress_manager.stress_changed.connect(soundscape_manager.on_stress_changed)

	# Connect stress to membrane walls
	if stress_manager:
		stress_manager.stress_changed.connect(_on_stress_to_walls)

	# Setup audio-visual sync bridge
	if audio_visual_sync:
		audio_visual_sync.setup(circuit_network, soundscape_manager)


func _on_player_speed_changed(speed: float) -> void:
	if stress_manager:
		stress_manager.on_speed_changed(speed)

	# Also pass speed directly to circuit network for proximity calculations
	if circuit_network and _ictio:
		circuit_network.on_player_moved(_ictio.global_position, speed)


func get_stress_level() -> float:
	if stress_manager:
		return stress_manager.get_stress()
	return 0.0


func get_player_position() -> Vector2:
	if _ictio:
		return _ictio.global_position
	return Vector2.ZERO


func _on_stress_to_walls(stress: float) -> void:
	for wall in get_tree().get_nodes_in_group("membrane_walls"):
		if wall.has_method("on_stress_changed"):
			wall.on_stress_changed(stress)
