extends StaticBody2D
class_name MembraneWall

## A single organic membrane wall segment.
## Generates collision + bioluminescent glow from a centerline path.
## Reacts to stress level from the NervousSystem.

# --- Wall shape (set by chamber_layout.gd) ---
var wall_points: PackedVector2Array = PackedVector2Array()
var wall_thickness: float = 10.0

# --- Glow visual settings ---
var glow_color_calm: Color = Color(0.04, 0.25, 0.42, 0.25)
var glow_color_stress: Color = Color(0.25, 0.06, 0.10, 0.40)
var glow_width_calm: float = 1.5
var glow_width_stress: float = 2.5

# --- Light settings ---
var light_energy_calm: float = 0.12
var light_energy_stress: float = 0.35
var light_texture_scale: float = 3.0

# --- Organic curve smoothing ---
var curve_segments: int = 8
var curve_variance: float = 4.0

# --- Internal state ---
var _stress_level: float = 0.0
var _target_stress: float = 0.0
var _glow_line: Line2D
var _glow_light: PointLight2D
var _collision_poly: CollisionPolygon2D

# Shader reference
var _shader: Shader


func _ready() -> void:
	add_to_group("membrane_walls")
	if wall_points.size() >= 2:
		_build()


func setup(points: PackedVector2Array, thickness: float = 10.0) -> void:
	wall_points = points
	wall_thickness = thickness
	if is_inside_tree():
		_build()


func _build() -> void:
	# Clear any previous children
	for child in get_children():
		child.queue_free()

	_build_collision_polygon()
	_build_glow_line()
	_build_glow_light()


func _build_collision_polygon() -> void:
	_collision_poly = CollisionPolygon2D.new()

	# Generate thin ribbon polygon from centerline
	var forward_strip: PackedVector2Array = PackedVector2Array()
	var backward_strip: PackedVector2Array = PackedVector2Array()
	var half_thick: float = wall_thickness / 2.0

	for i in range(wall_points.size()):
		var perp: Vector2 = _get_perpendicular_at(i)
		forward_strip.append(wall_points[i] + perp * half_thick)
		backward_strip.append(wall_points[i] - perp * half_thick)

	# Build polygon: forward side then backward side reversed
	var polygon: PackedVector2Array = PackedVector2Array()
	for p in forward_strip:
		polygon.append(p)
	for i in range(backward_strip.size() - 1, -1, -1):
		polygon.append(backward_strip[i])

	_collision_poly.polygon = polygon
	add_child(_collision_poly)


func _get_perpendicular_at(index: int) -> Vector2:
	var direction: Vector2
	if index == 0:
		direction = (wall_points[1] - wall_points[0]).normalized()
	elif index == wall_points.size() - 1:
		direction = (wall_points[index] - wall_points[index - 1]).normalized()
	else:
		# Average of incoming and outgoing directions for smooth corners
		var d1: Vector2 = (wall_points[index] - wall_points[index - 1]).normalized()
		var d2: Vector2 = (wall_points[index + 1] - wall_points[index]).normalized()
		direction = ((d1 + d2) / 2.0).normalized()
	return Vector2(-direction.y, direction.x)


func _build_glow_line() -> void:
	_glow_line = Line2D.new()
	_glow_line.default_color = glow_color_calm
	_glow_line.width = glow_width_calm
	_glow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_line.texture_mode = Line2D.LINE_TEXTURE_TILE

	# Tapered width curve (thin at ends, full in middle)
	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 0.45))
	width_curve.add_point(Vector2(0.5, 1.0))
	width_curve.add_point(Vector2(1.0, 0.45))
	_glow_line.width_curve = width_curve

	# Generate smooth curve via Catmull-Rom spline
	var smooth_points: PackedVector2Array = _catmull_rom_spline(wall_points, curve_segments)
	_glow_line.points = smooth_points

	# Apply shader for organic breathing
	_apply_shader()

	add_child(_glow_line)


func _apply_shader() -> void:
	if _shader == null:
		_shader = load("res://shaders/circuit_wave.gdshader") as Shader
	if _shader == null:
		return

	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("distortion", 0.03)
	mat.set_shader_parameter("audio_pulse", 0.0)
	mat.set_shader_parameter("wave_speed", 1.2)
	mat.set_shader_parameter("wave_frequency", 5.0)
	mat.set_shader_parameter("wave_amplitude", 3.0)
	mat.set_shader_parameter("noise_scale", 3.0)
	mat.set_shader_parameter("noise_speed", 0.3)
	_glow_line.material = mat


func _build_glow_light() -> void:
	_glow_light = PointLight2D.new()

	# Position at wall midpoint
	var mid_index: int = wall_points.size() / 2
	_glow_light.position = wall_points[mid_index]

	# Use bubble.png as light texture (same as lightnodes and player)
	var light_tex: Texture2D = load("res://assets/art/bubble.png") as Texture2D
	if light_tex:
		_glow_light.texture = light_tex

	_glow_light.texture_scale = light_texture_scale
	_glow_light.energy = light_energy_calm
	_glow_light.color = Color(glow_color_calm.r, glow_color_calm.g, glow_color_calm.b, 1.0)

	add_child(_glow_light)


func _process(delta: float) -> void:
	# Smooth stress interpolation
	_stress_level = lerpf(_stress_level, _target_stress, delta * 4.0)
	_update_glow()


func _update_glow() -> void:
	if _glow_line:
		_glow_line.default_color = glow_color_calm.lerp(glow_color_stress, _stress_level)
		_glow_line.width = lerpf(glow_width_calm, glow_width_stress, _stress_level)

	if _glow_light:
		_glow_light.energy = lerpf(light_energy_calm, light_energy_stress, _stress_level)
		var light_color: Color = glow_color_calm.lerp(glow_color_stress, _stress_level)
		_glow_light.color = Color(light_color.r, light_color.g, light_color.b, 1.0)

	# Update shader distortion with stress
	if _glow_line and _glow_line.material:
		var distortion: float = lerpf(0.03, 0.12, _stress_level)
		_glow_line.material.set_shader_parameter("distortion", distortion)


func on_stress_changed(stress: float) -> void:
	_target_stress = stress


# --- Catmull-Rom spline (ported from circuit_line.gd) ---

func _catmull_rom_spline(control_pts: PackedVector2Array, segments: int) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if control_pts.size() < 2:
		return control_pts

	# Extend ends for Catmull-Rom
	var extended: PackedVector2Array = PackedVector2Array()
	extended.append(control_pts[0] + (control_pts[0] - control_pts[1]))
	for p in control_pts:
		extended.append(p)
	var last_idx: int = control_pts.size() - 1
	extended.append(control_pts[last_idx] + (control_pts[last_idx] - control_pts[last_idx - 1]))

	# Interpolate between each pair
	for i in range(1, extended.size() - 2):
		var p0: Vector2 = extended[i - 1]
		var p1: Vector2 = extended[i]
		var p2: Vector2 = extended[i + 1]
		var p3: Vector2 = extended[i + 2]
		for j in range(segments):
			var t: float = float(j) / float(segments)
			result.append(_catmull_rom_point(p0, p1, p2, p3, t))

	result.append(control_pts[control_pts.size() - 1])
	return result


func _catmull_rom_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
