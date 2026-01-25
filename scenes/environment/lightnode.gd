extends Area2D
class_name Lightnode

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var point_light: PointLight2D = $PointLight2D

var current_angle_deg: float = 0.0

# --- Visual / per-instance sprite ---
@export var icon: Texture2D
@export var icon_scale: float = 1.0
@export var icon_modulate: Color = Color.WHITE

# --- Lit state visuals ---
@export var dark_alpha: float = 0.3           # how dim when unlit
@export var lit_color: Color = Color(1.0, 1.0, 0.8)  # warm glow when fixed
@export var lit_scale_boost: float = 1.2      # scale up when lit

# --- Point light settings ---
@export var light_energy: float = 1.5         # how bright the light is when lit
@export var light_color: Color = Color(1.0, 0.95, 0.8)  # warm light color

# --- Speed Moderation (Mechanic I) ---
@export var min_effective_speed: float = 40.0   # below this = too slow, no rotation
@export var max_effective_speed: float = 160.0  # above this = too fast, no rotation
@export var knockback_pixels: float = 48.0      # bounce distance on wrong speed
@export var proximity_radius: float = 120.0     # distance for color feedback

# --- Internal state ---
var _wobble_tween: Tween = null
var _original_modulate: Color
var _is_fixed: bool = false  # true once lightnode reaches target angle

# --- Rotation puzzle ---
@export var angle_step_deg: float = 45.0
@export var start_angle_deg: float = 0.0
@export_range(0.0, 359.0, 1.0) var required_angle_deg: float = 0.0
@export var angle_tolerance_deg: float = 1.0   # how close is "good enough" (in degrees)

# --- SFX (optional) ---
@export var pickup_sound: AudioStream
@export var rotate_sound: AudioStream
@export var fail_sound: AudioStream


func _wrap360(v: float) -> float:
	return fposmod(v, 360.0)


func _angle_delta(a: float, b: float) -> float:
	var ra: float = _wrap360(a)
	var rb: float = _wrap360(b)
	var d: float = abs(ra - rb)
	return min(d, 360.0 - d)


func _is_angle_match(a: float, b: float, tol: float) -> bool:
	return _angle_delta(a, b) <= tol


func _ready() -> void:
	# Per-instance sprite look
	if icon:
		sprite.texture = icon
	sprite.scale = Vector2.ONE * icon_scale

	# Start in dark/unlit state
	var dark_color := icon_modulate
	dark_color.a = dark_alpha
	sprite.modulate = dark_color

	if sprite.has_method("set_centered"):
		sprite.centered = true

	# Start at a defined orientation
	current_angle_deg = _wrap360(start_angle_deg)
	sprite.rotation_degrees = current_angle_deg

	# Optional: animation
	if anim:
		anim.play("pulse")

	# Optional: assign pickup sound via export
	if pickup_sound and audio_player:
		audio_player.stream = pickup_sound

	# Ensure signal is connected
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	# Group for LevelController counting
	add_to_group("lightnodes")

	# Store original color for proximity feedback (dark state)
	_original_modulate = sprite.modulate


func _process(_delta: float) -> void:
	# Skip proximity feedback if already fixed (lit)
	if _is_fixed:
		return

	# Proximity color feedback based on Ictio's speed
	var ictio := get_node_or_null("%Ictio")
	if ictio == null or sprite == null:
		return

	var dist: float = global_position.distance_to(ictio.global_position)
	if dist > proximity_radius:
		# Outside range - restore original color (dark state)
		sprite.modulate = _original_modulate
		return

	# Inside proximity range - tint based on speed
	var speed: float = ictio.velocity.length()
	var tint: Color
	if speed < min_effective_speed:
		# Too slow - blue-grey tint
		tint = Color(0.6, 0.7, 0.9)
	elif speed > max_effective_speed:
		# Too fast - reddish tint
		tint = Color(1.0, 0.6, 0.5)
	else:
		# Goldilocks zone - green tint (good!)
		tint = Color(0.5, 1.0, 0.6)

	# Blend tint with original based on proximity (closer = stronger tint)
	var blend: float = 1.0 - (dist / proximity_radius)
	sprite.modulate = _original_modulate.lerp(tint, blend * 0.7)


func _wobble() -> void:
	# Visual feedback: object wobbles but does NOT rotate
	if sprite == null:
		return

	# Kill any existing wobble to prevent drift from mid-animation captures
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	# Use logical angle (current_angle_deg), not visual angle, as the return target
	var target_rot: float = current_angle_deg
	_wobble_tween = create_tween()
	_wobble_tween.tween_property(sprite, "rotation_degrees", target_rot + 8.0, 0.05)
	_wobble_tween.tween_property(sprite, "rotation_degrees", target_rot - 8.0, 0.1)
	_wobble_tween.tween_property(sprite, "rotation_degrees", target_rot + 4.0, 0.08)
	_wobble_tween.tween_property(sprite, "rotation_degrees", target_rot, 0.07)


func _on_body_entered(body: Node) -> void:
	# Only react to Ictio
	if body == null or body.name != "Ictio":
		return
	var ictio: CharacterBody2D = body as CharacterBody2D
	if ictio == null:
		return

	# --- Always bounce Ictio back on collision ---
	var dir: Vector2 = (ictio.global_position - global_position).normalized()
	ictio.set_deferred("global_position", ictio.global_position + dir * knockback_pixels)
	var v: Vector2 = ictio.velocity
	v = v - dir * 100.0
	ictio.set_deferred("velocity", v)

	# --- Speed Moderation (Mechanic I) ---
	var speed: float = ictio.velocity.length()
	var in_goldilocks: bool = speed >= min_effective_speed and speed <= max_effective_speed

	if not in_goldilocks:
		# Wrong speed: wobble, NO rotation
		_wobble()

		# Fail SFX
		if fail_sound and audio_player:
			audio_player.stream = fail_sound
			audio_player.volume_db = -6.0
			audio_player.play()
		return

	# --- Correct speed: rotate by one step ---
	current_angle_deg = _wrap360(current_angle_deg + angle_step_deg)
	sprite.rotation_degrees = current_angle_deg

	# Rotate tick SFX
	if rotate_sound and audio_player:
		audio_player.stream = rotate_sound
		audio_player.volume_db = -10.0
		audio_player.play()

	# --- Check if puzzle solved ---
	if _is_angle_match(current_angle_deg, required_angle_deg, angle_tolerance_deg):
		_is_fixed = true

		var lc = get_node_or_null("%LevelController")
		if lc and lc.has_method("notify_lightnode_fixed"):
			lc.notify_lightnode_fixed()

		# Fixed SFX
		if pickup_sound and audio_player:
			audio_player.stream = pickup_sound
			audio_player.volume_db = -6.0
			audio_player.play()

		# Disable collisions (no longer interactable)
		if shape:
			shape.set_deferred("disabled", true)
		set_deferred("monitoring", false)

		# Transition to lit state: glow brightly instead of disappearing
		_become_lit()


func _become_lit() -> void:
	# Stop any ongoing wobble
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	# Stop pulse animation
	if anim:
		anim.stop()

	# Calculate lit state values
	var target_scale: Vector2 = Vector2.ONE * icon_scale * lit_scale_boost
	var target_color: Color = lit_color

	# Enable the point light
	if point_light:
		point_light.color = light_color
		point_light.enabled = true

	# Animate transition from dark to lit
	var tween := create_tween()
	tween.set_parallel(true)

	# Scale up slightly
	tween.tween_property(sprite, "scale", target_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Brighten to lit color
	tween.tween_property(sprite, "modulate", target_color, 0.3).set_ease(Tween.EASE_OUT)

	# Fade in the point light
	if point_light:
		tween.tween_property(point_light, "energy", light_energy, 0.5).set_ease(Tween.EASE_OUT)

	# After initial transition, start gentle glow pulse
	await tween.finished
	_start_glow_pulse()


func _start_glow_pulse() -> void:
	# Continuous gentle pulse to show the lightnode is alive and glowing
	var base_scale: Vector2 = Vector2.ONE * icon_scale * lit_scale_boost
	var pulse_scale: Vector2 = base_scale * 1.08

	var glow_tween := create_tween()
	glow_tween.set_loops()  # Loop forever

	# Gentle scale pulse
	glow_tween.tween_property(sprite, "scale", pulse_scale, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(sprite, "scale", base_scale, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
