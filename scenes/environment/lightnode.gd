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
@export var icon_modulate: Color = Color(0.3, 0.2, 0.55)

# --- Lit state visuals ---
@export var dark_alpha: float = 0.9           # how dim when unlit
@export var lit_color: Color = Color(0.952941, 0.027451, 0.043137)  # warm glow when fixed
@export var lit_scale_boost: float = 1.2      # scale up when lit

# --- Point light settings ---
@export var light_energy: float = 1.5         # how bright the light is when lit
@export var light_color: Color = Color(0.952941, 0.027451, 0.043137)  # warm light color

# --- Speed Moderation (Mechanic I) ---
@export var min_effective_speed: float = 40.0   # below this = too slow, no rotation
@export var max_effective_speed: float = 160.0  # above this = too fast, no rotation
@export var knockback_pixels: float = 48.0      # bounce distance on wrong speed
@export var proximity_radius: float = 120.0     # distance for color feedback

# --- Progress glow ---
@export var progress_max_energy: float = 0.45
@export var progress_light_color: Color = Color(0.15, 0.15, 0.6)  # muted blue, distinct from lit red
var _initial_angle_delta: float = 0.0
var _progress: float = 0.0

# --- Internal state ---
var _wobble_tween: Tween = null
var _reject_tween: Tween = null
var _reject_cooldown: bool = false
var _original_modulate: Color
var _is_fixed: bool = false  # true once lightnode reaches target angle
var _ictio: CharacterBody2D  # cached player reference

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

	# Compute initial distance for progress tracking
	_initial_angle_delta = _angle_delta(current_angle_deg, required_angle_deg)
	if _initial_angle_delta < angle_tolerance_deg:
		_initial_angle_delta = 0.0

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

	# Cache player reference
	await get_tree().process_frame
	_ictio = get_node_or_null("%Ictio")


func _process(delta: float) -> void:
	# Skip proximity feedback if already fixed (lit) or mid-rejection
	if _is_fixed or _reject_cooldown:
		return

	if _ictio == null or not is_instance_valid(_ictio) or sprite == null:
		return

	var dist: float = global_position.distance_to(_ictio.global_position)
	if dist > proximity_radius:
		# Outside range — restore original state
		sprite.modulate = _original_modulate
		sprite.scale = Vector2.ONE * icon_scale
		if point_light and _progress < 0.01:
			point_light.energy = lerpf(point_light.energy, 0.0, 4.0 * delta)
		return

	# Inside proximity range — tint based on speed
	var speed: float = _ictio.velocity.length()
	var blend: float = 1.0 - (dist / proximity_radius)
	var in_goldilocks: bool = speed >= min_effective_speed and speed <= max_effective_speed

	var tint: Color
	if speed < min_effective_speed:
		tint = Color(0.027451, 0.062745, 0.454902)
	elif speed > max_effective_speed:
		tint = Color(0.952941, 0.027451, 0.043137)
	else:
		tint = Color(0.011765, 0.011765, 0.803922)

	sprite.modulate = _original_modulate.lerp(tint, blend * 0.7)

	# Welcoming pulse when approaching at correct speed
	if in_goldilocks and speed > 5.0:
		var t: float = float(Time.get_ticks_msec()) / 1000.0
		var pulse: float = 1.0 + sin(t * 3.0) * 0.04 * blend
		sprite.scale = Vector2.ONE * icon_scale * pulse

		# Proximity glow on point light
		if point_light:
			var target_energy: float = blend * 0.25
			point_light.color = progress_light_color
			point_light.enabled = true
			point_light.energy = lerpf(point_light.energy, target_energy, 4.0 * delta)
	else:
		sprite.scale = Vector2.ONE * icon_scale
		if point_light and _progress < 0.01:
			point_light.energy = lerpf(point_light.energy, 0.0, 4.0 * delta)


func _reject(is_too_fast: bool) -> void:
	if sprite == null or _reject_cooldown:
		return
	_reject_cooldown = true

	# Kill any existing tweens
	if _reject_tween and _reject_tween.is_valid():
		_reject_tween.kill()
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	# Stop pulse animation to prevent scale fighting
	if anim:
		anim.stop()

	# Direction-dependent parameters
	var flash_color: Color
	var scale_target: Vector2
	var wobble_amp: float
	var swing_time: float
	if is_too_fast:
		flash_color = Color(0.952941, 0.027451, 0.043137)  # red
		scale_target = Vector2.ONE * icon_scale * 1.25
		wobble_amp = 15.0
		swing_time = 0.06
	else:
		flash_color = Color(0.027451, 0.062745, 0.454902)  # deep blue
		scale_target = Vector2.ONE * icon_scale * 0.75
		wobble_amp = 10.0
		swing_time = 0.09

	var base_scale: Vector2 = Vector2.ONE * icon_scale
	var target_rot: float = current_angle_deg

	_reject_tween = create_tween()

	# Phase 1: snap to flash state (parallel)
	_reject_tween.set_parallel(true)
	_reject_tween.tween_property(sprite, "modulate", flash_color, 0.08)
	_reject_tween.tween_property(sprite, "scale", scale_target, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_reject_tween.tween_property(sprite, "rotation_degrees", target_rot + wobble_amp, 0.08)
	if point_light:
		_reject_tween.tween_property(point_light, "energy", 0.8, 0.08)
		point_light.color = flash_color
		point_light.enabled = true

	# Phase 2: oscillation swings (sequential)
	_reject_tween.chain().set_parallel(false)
	_reject_tween.tween_property(sprite, "rotation_degrees", target_rot - wobble_amp, swing_time)
	_reject_tween.tween_property(sprite, "rotation_degrees", target_rot + wobble_amp, swing_time)
	_reject_tween.tween_property(sprite, "rotation_degrees", target_rot - wobble_amp, swing_time)

	# Phase 3: recover to normal (parallel)
	_reject_tween.chain().set_parallel(true)
	_reject_tween.tween_property(sprite, "modulate", _original_modulate, 0.2).set_ease(Tween.EASE_OUT)
	_reject_tween.tween_property(sprite, "scale", base_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_reject_tween.tween_property(sprite, "rotation_degrees", target_rot, 0.2).set_ease(Tween.EASE_OUT)
	if point_light:
		_reject_tween.tween_property(point_light, "energy", 0.0, 0.2).set_ease(Tween.EASE_OUT)

	# Cleanup callback
	_reject_tween.chain().set_parallel(false)
	_reject_tween.tween_callback(_reject_cleanup)


func _reject_cleanup() -> void:
	_reject_cooldown = false
	if point_light:
		if _progress > 0.01:
			# Restore progress glow instead of blanking
			point_light.color = progress_light_color
			point_light.energy = _progress * progress_max_energy
			point_light.enabled = true
		else:
			point_light.enabled = false
	if anim:
		anim.play("pulse")


func _play_reject_tone(is_too_fast: bool) -> void:
	if audio_player == null:
		return
	var beep_stream := load("res://assets/audio/beepbeep.mp3")
	if beep_stream == null:
		return
	audio_player.stream = beep_stream
	audio_player.pitch_scale = 1.8 if is_too_fast else 0.6
	audio_player.volume_db = -8.0
	audio_player.play()
	# Reset pitch after sound plays
	var reset_tween := create_tween()
	reset_tween.tween_callback(func(): audio_player.pitch_scale = 1.0).set_delay(0.3)


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
		var is_too_fast: bool = speed > max_effective_speed
		_reject(is_too_fast)
		_play_reject_tone(is_too_fast)
		return

	# --- Correct speed: rotate by one step ---
	current_angle_deg = _wrap360(current_angle_deg + angle_step_deg)
	sprite.rotation_degrees = current_angle_deg

	# Update progress glow
	_update_progress_glow()

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


func _update_progress_glow() -> void:
	if _initial_angle_delta <= 0.0 or point_light == null:
		return
	var remaining: float = _angle_delta(current_angle_deg, required_angle_deg)
	_progress = clampf(1.0 - (remaining / _initial_angle_delta), 0.0, 1.0)
	point_light.color = progress_light_color
	point_light.enabled = true
	var tween := create_tween()
	tween.tween_property(point_light, "energy", _progress * progress_max_energy, 0.3).set_ease(Tween.EASE_OUT)


func _become_lit() -> void:
	# Stop any ongoing rejection/wobble
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()
	if _reject_tween and _reject_tween.is_valid():
		_reject_tween.kill()
	_reject_cooldown = false

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
