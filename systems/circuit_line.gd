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
@export var segments_per_control: int = 10  # smoothness of curves
@export var curve_variance: float = 55.0    # how far control points deviate
@export var control_point_count: int = 4    # number of intermediate control points

# Visual palette (overridable by CircuitNetwork)
@export var dim_color: Color = Color(0.04, 0.09, 0.52, 0.5)
@export var lit_color: Color = Color(0.011765, 0.011765, 0.803922, 0.8)
@export var base_width: float = 1.4
@export var lit_width: float = 2.2

# Distortion state (set by shader uniforms)
var distortion_intensity: float = 0.0
var audio_pulse: float = 0.0

# Base curve points (before distortion)
var _base_points: PackedVector2Array
var _control_points: PackedVector2Array


func _ready() -> void:
	# Set visual properties
	width = base_width
	default_color = dim_color
	texture_mode = Line2D.LINE_TEXTURE_TILE
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	_setup_width_curve()


func setup(from_node: Node2D, to_node: Node2D, line_index: int = 0, line_total: int = 1, endpoint_spread: float = 0.0) -> void:
	start_node = from_node
	end_node = to_node
	_apply_endpoint_offsets(from_node, to_node, line_index, line_total, endpoint_spread)
	_generate_organic_curve()


func _setup_width_curve() -> void:
	# Thin, tendril-like profile with subtle taper at the ends
	if width_curve:
		return
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.45))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.45))
	width_curve = curve


func _apply_endpoint_offsets(from_node: Node2D, to_node: Node2D, line_index: int, line_total: int, endpoint_spread: float) -> void:
	var raw_start: Vector2 = from_node.global_position
	var raw_end: Vector2 = to_node.global_position
	var direction: Vector2 = (raw_end - raw_start).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var spread_factor: float = 0.0
	if line_total > 1:
		spread_factor = (float(line_index) / float(line_total - 1)) * 2.0 - 1.0
	var bundle_offset: Vector2 = perpendicular * endpoint_spread * spread_factor
	var jitter: Vector2 = perpendicular * randf_range(-endpoint_spread * 0.15, endpoint_spread * 0.15)
	jitter += direction * randf_range(-endpoint_spread * 0.1, endpoint_spread * 0.1)
	start_pos = raw_start + bundle_offset + jitter
	end_pos = raw_end + bundle_offset - jitter


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
	default_color = dim_color.lerp(lit_color, level)
	width = lerpf(base_width, lit_width, level)


func set_palette(dim: Color, lit: Color) -> void:
	dim_color = dim
	lit_color = lit
	default_color = dim_color


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
