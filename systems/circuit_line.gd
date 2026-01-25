extends Line2D
class_name CircuitLine

## A single organic circuit line connecting two lightnodes.
## Uses Catmull-Rom spline for organic curves with shader-based distortion.

# Connection endpoints (global positions)
var start_pos: Vector2
var end_pos: Vector2

# References to connected lightnodes
var start_node: Node2D
var end_node: Node2D

# Curve generation settings
@export var segments_per_control: int = 8   # smoothness of curves
@export var curve_variance: float = 40.0    # how far control points deviate
@export var control_point_count: int = 3    # number of intermediate control points

# Distortion state (set by shader uniforms)
var distortion_intensity: float = 0.0
var audio_pulse: float = 0.0

# Base curve points (before distortion)
var _base_points: PackedVector2Array
var _control_points: PackedVector2Array


func _ready() -> void:
	# Set visual properties
	width = 3.0
	default_color = Color(0.7, 0.8, 0.9, 0.5)  # light blue-white, visible
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND


func setup(from_node: Node2D, to_node: Node2D) -> void:
	start_node = from_node
	end_node = to_node
	start_pos = from_node.global_position
	end_pos = to_node.global_position
	_generate_organic_curve()


func _generate_organic_curve() -> void:
	# Generate control points with organic randomness
	_control_points = PackedVector2Array()
	_control_points.append(start_pos)

	var direction: Vector2 = (end_pos - start_pos).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	@warning_ignore("UNUSED_VARIABLE")
	var total_length: float = start_pos.distance_to(end_pos)

	# Add intermediate control points with perpendicular variance
	for i in range(control_point_count):
		var t: float = float(i + 1) / float(control_point_count + 1)
		var base_point: Vector2 = start_pos.lerp(end_pos, t)
		var offset: Vector2 = perpendicular * randf_range(-curve_variance, curve_variance)
		# Add some "wandering" with sine for organic feel
		offset += direction * randf_range(-curve_variance * 0.3, curve_variance * 0.3)
		_control_points.append(base_point + offset)

	_control_points.append(end_pos)

	# Generate smooth curve through control points using Catmull-Rom
	_base_points = _catmull_rom_spline(_control_points, segments_per_control)
	points = _base_points


func _catmull_rom_spline(control_pts: PackedVector2Array, segments: int) -> PackedVector2Array:
	## Generate smooth curve through all control points using Catmull-Rom interpolation
	var result: PackedVector2Array = PackedVector2Array()

	if control_pts.size() < 2:
		return result

	# Need 4 points for Catmull-Rom, so we extend the ends
	var extended: PackedVector2Array = PackedVector2Array()
	# Mirror first point
	extended.append(control_pts[0] + (control_pts[0] - control_pts[1]))
	for p in control_pts:
		extended.append(p)
	# Mirror last point
	var last_idx: int = control_pts.size() - 1
	extended.append(control_pts[last_idx] + (control_pts[last_idx] - control_pts[last_idx - 1]))

	# Interpolate between each pair of middle points
	for i in range(1, extended.size() - 2):
		var p0: Vector2 = extended[i - 1]
		var p1: Vector2 = extended[i]
		var p2: Vector2 = extended[i + 1]
		var p3: Vector2 = extended[i + 2]

		for j in range(segments):
			var t: float = float(j) / float(segments)
			result.append(_catmull_rom_point(p0, p1, p2, p3, t))

	# Add final point
	result.append(control_pts[control_pts.size() - 1])

	return result


func _catmull_rom_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	## Calculate single point on Catmull-Rom spline
	var t2: float = t * t
	var t3: float = t2 * t

	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func set_distortion(intensity: float) -> void:
	distortion_intensity = intensity
	if material:
		material.set_shader_parameter("distortion", intensity)


func set_audio_pulse(pulse: float) -> void:
	audio_pulse = pulse
	if material:
		material.set_shader_parameter("audio_pulse", pulse)


func set_activation_level(level: float) -> void:
	## level 0 = dim, level 1 = bright white (both lightnodes fixed)
	var alpha: float = lerpf(0.5, 0.95, level)
	var brightness: float = lerpf(0.7, 1.0, level)
	# White-ish color that brightens as lightnodes are fixed
	default_color = Color(brightness, brightness * 1.05, brightness * 1.1, alpha)
	width = lerpf(3.0, 5.0, level)


func get_nearest_point_distance(pos: Vector2) -> float:
	## Find distance from pos to nearest point on the line
	var min_dist: float = INF
	for p in points:
		# Convert local point to global
		var global_p: Vector2 = to_global(p)
		var dist: float = pos.distance_to(global_p)
		if dist < min_dist:
			min_dist = dist
	return min_dist


func is_connected_to(node: Node2D) -> bool:
	return start_node == node or end_node == node
