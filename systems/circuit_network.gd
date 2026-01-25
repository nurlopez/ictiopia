extends Node2D
class_name CircuitNetwork

## Manages the network of circuit lines connecting lightnodes.
## Creates organic nervous-system-like connections between all nodes.

const CircuitLineScene := preload("res://systems/circuit_line.gd")

# Distortion settings
@export var base_distortion: float = 0.1         # minimum distortion
@export var max_distortion: float = 0.8          # maximum at full stress
@export var proximity_radius: float = 200.0      # distance for player proximity effects
@export var proximity_boost: float = 0.3         # extra distortion when player is near

# Visual settings
@export var line_color_dim: Color = Color(0.2, 0.4, 0.6, 0.3)
@export var line_color_lit: Color = Color(0.4, 0.7, 0.9, 0.7)

# State
var _lines: Array[CircuitLine] = []
var _lightnodes: Array[Node2D] = []
var _stress_level: float = 0.0
var _player_pos: Vector2
var _player_speed: float = 0.0

# Shader for wave distortion
var _circuit_shader: ShaderMaterial


func _ready() -> void:
	z_index = 1  # render above tiles but below player/lightnodes
	call_deferred("_late_init")


func _late_init() -> void:
	_find_lightnodes()
	_create_circuit_network()
	_setup_shader()


func _find_lightnodes() -> void:
	_lightnodes.clear()
	var nodes := get_tree().get_nodes_in_group("lightnodes")
	for node in nodes:
		if node is Node2D:
			_lightnodes.append(node as Node2D)
	print("[CircuitNetwork] Found ", _lightnodes.size(), " lightnodes")


func _create_circuit_network() -> void:
	## Create triangle topology - connect all 3 lightnodes
	if _lightnodes.size() < 2:
		push_warning("[CircuitNetwork] Need at least 2 lightnodes to create network")
		return

	# For triangle: connect each pair
	for i in range(_lightnodes.size()):
		for j in range(i + 1, _lightnodes.size()):
			_create_line(_lightnodes[i], _lightnodes[j])

	print("[CircuitNetwork] Created ", _lines.size(), " circuit lines")


func _create_line(from_node: Node2D, to_node: Node2D) -> CircuitLine:
	var line := CircuitLine.new()
	add_child(line)
	line.setup(from_node, to_node)
	_lines.append(line)
	return line


func _setup_shader() -> void:
	# Load shader if available
	var shader := load("res://shaders/circuit_wave.gdshader") as Shader
	if shader:
		_circuit_shader = ShaderMaterial.new()
		_circuit_shader.shader = shader
		for line in _lines:
			line.material = _circuit_shader.duplicate()


func _process(_delta: float) -> void:
	_update_line_distortions()
	_update_line_activations()


func _update_line_distortions() -> void:
	for line in _lines:
		# Base distortion from stress
		var stress_distortion: float = lerpf(base_distortion, max_distortion, _stress_level)

		# Add proximity boost if player is near this line
		var dist: float = line.get_nearest_point_distance(_player_pos)
		var proximity_factor: float = 1.0 - clampf(dist / proximity_radius, 0.0, 1.0)
		var proximity_distortion: float = proximity_boost * proximity_factor

		# Speed affects distortion intensity when near
		var speed_factor: float = 0.0
		if _player_speed > 160.0:  # too fast
			speed_factor = clampf((_player_speed - 160.0) / 100.0, 0.0, 1.0)
		elif _player_speed < 40.0 and _player_speed > 0.0:  # too slow
			speed_factor = clampf((40.0 - _player_speed) / 40.0, 0.0, 0.5)

		var total_distortion: float = stress_distortion + proximity_distortion * (1.0 + speed_factor)
		line.set_distortion(clampf(total_distortion, 0.0, 1.0))


func _update_line_activations() -> void:
	## Update line brightness based on connected lightnode states
	for line in _lines:
		var activation := 0.0
		# Check if connected lightnodes are fixed
		if _is_lightnode_fixed(line.start_node):
			activation += 0.5
		if _is_lightnode_fixed(line.end_node):
			activation += 0.5
		line.set_activation_level(activation)


func _is_lightnode_fixed(node: Node2D) -> bool:
	if node == null:
		return false
	# Check if the lightnode has _is_fixed property
	if node.get("_is_fixed"):
		return true
	return false


func on_stress_changed(stress: float) -> void:
	_stress_level = stress


func on_player_moved(pos: Vector2, speed: float) -> void:
	_player_pos = pos
	_player_speed = speed


func on_audio_pulse(intensity: float) -> void:
	## Called by audio-visual sync to add rhythmic pulsing
	for line in _lines:
		line.set_audio_pulse(intensity)
