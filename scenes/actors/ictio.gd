extends CharacterBody2D

# --- Movement tunables ---
@export var max_speed: float = 200.0
@export var accel: float = 360.0
@export var friction: float = 420.0

# --- Goldilocks zone (keep in sync with lightnodes) ---
@export var min_effective_speed: float = 40.0
@export var max_effective_speed: float = 160.0

# --- Stabilize (hold to keep speed) ---
@export var stabilize_accel_scale: float = 0.2
@export var stabilize_friction_scale: float = 2.0
@export var stabilize_turn_speed: float = 3.5

# --- Bubbles (GPUParticles2D) refs ---
@onready var bubbles: GPUParticles2D = $Bubbles
@onready var bubbles_mat: ParticleProcessMaterial = bubbles.process_material
# --- Speed zone colors ---
const ZONE_SLOW_COLOR := Color(0.027451, 0.062745, 0.454902)   # deep blue
const ZONE_GOOD_COLOR := Color(0.011765, 0.011765, 0.803922)   # bright blue
const ZONE_FAST_COLOR := Color(0.952941, 0.027451, 0.043137)   # red
@export var zone_color_lerp: float = 4.0

signal speed_changed(speed: float)

func _ready() -> void:
	# One-time particle defaults
	if bubbles_mat:
		# gentle upward drift so bubbles feel watery
		bubbles_mat.gravity = Vector3(0.0, -15.0, 0.0)
		# slight base direction to the left (overridden each frame by velocity)
		bubbles_mat.direction = Vector3(-1.0, 0.0, 0.0)
		# base spread and size (tighter trail)
		bubbles_mat.spread = 12.0
		# ✅ scale is float min/max in 4.3
		bubbles_mat.scale_min = 0.55
		bubbles_mat.scale_max = 0.65
		# safe base velocities (float min/max)
		bubbles_mat.initial_velocity_min = 40.0
		bubbles_mat.initial_velocity_max = 60.0

func _physics_process(delta: float) -> void:
	# --- Input → desired velocity ---
	var input_vec: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	)
	var stabilizing: bool = Input.is_action_pressed("stabilize")

	if stabilizing:
		# Hold-to-stabilize: damp rapid accel/decel without auto-correcting to Goldilocks.
		var stabilizing_speed: float = velocity.length()

		# If player is steering, allow gentle re-direction at current speed.
		if input_vec != Vector2.ZERO and stabilizing_speed > 1.0:
			var steer_target: Vector2 = input_vec.normalized() * stabilizing_speed
			velocity = velocity.lerp(steer_target, stabilize_turn_speed * delta)

		# If player is not steering, reduce deceleration so speed holds longer.
		if input_vec == Vector2.ZERO:
			velocity = velocity.move_toward(Vector2.ZERO, (friction * stabilize_accel_scale) * delta)
		else:
			# If steering, soften acceleration changes.
			var desired: Vector2 = input_vec.normalized() * max_speed
			var diff: Vector2 = desired - velocity
			var max_change: float = accel * stabilize_accel_scale * delta
			if diff.length() > max_change:
				diff = diff.normalized() * max_change
			velocity += diff
	else:
		var desired: Vector2 = input_vec.normalized() * max_speed
		var diff: Vector2 = desired - velocity

		# --- Accelerate toward desired ---
		var max_change: float = accel * delta
		if diff.length() > max_change:
			diff = diff.normalized() * max_change
		velocity += diff

		# --- Friction when idle ---
		if input_vec == Vector2.ZERO:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# --- Face movement direction ---
	if velocity.length() > 1.0:
		rotation = velocity.angle()

	# --- Emit speed for stress system ---
	var speed: float = velocity.length()
	speed_changed.emit(speed)

	# --- Speed zone bubbles + light color ---
	var zone_color: Color = ZONE_GOOD_COLOR
	if speed < 5.0:
		bubbles.emitting = false
	elif speed < min_effective_speed:
		bubbles.emitting = true
		bubbles.amount_ratio = lerpf(0.05, 0.3, speed / min_effective_speed)
		zone_color = ZONE_SLOW_COLOR
	elif speed <= max_effective_speed:
		bubbles.emitting = true
		var t: float = (speed - min_effective_speed) / (max_effective_speed - min_effective_speed)
		bubbles.amount_ratio = lerpf(0.3, 0.55, t)
		zone_color = ZONE_GOOD_COLOR
	else:
		bubbles.emitting = true
		var t: float = clampf((speed - max_effective_speed) / (max_speed - max_effective_speed), 0.0, 1.0)
		bubbles.amount_ratio = lerpf(0.55, 1.0, t)
		zone_color = ZONE_FAST_COLOR

	if bubbles.emitting:
		bubbles.modulate = bubbles.modulate.lerp(zone_color, zone_color_lerp * delta)
