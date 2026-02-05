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
@onready var stabilize_glow: PointLight2D = $PointLight2D

# --- Stabilize glow ---
@export var stabilize_glow_energy: float = 1.15
@export var stabilize_glow_lerp: float = 8.0

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

	# Stabilize glow (non-verbal cue)
	if stabilize_glow:
		var target_energy: float = stabilize_glow_energy if stabilizing else 0.6
		stabilize_glow.energy = lerpf(stabilize_glow.energy, target_energy, stabilize_glow_lerp * delta)

	move_and_slide()

	# --- Face movement direction ---
	if velocity.length() > 1.0:
		rotation = velocity.angle()

	# --- Emit speed for stress system ---
	var speed: float = velocity.length()
	speed_changed.emit(speed)

	# --- Bubbles: disabled ---
	bubbles.emitting = false
