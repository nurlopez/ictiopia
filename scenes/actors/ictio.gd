extends CharacterBody2D

# --- Movement tunables ---
@export var max_speed: float = 220.0
@export var accel: float = 1200.0
@export var friction: float = 900.0

# --- Bubbles (GPUParticles2D) refs ---
@onready var bubbles: GPUParticles2D = $Bubbles
@onready var bubbles_mat: ParticleProcessMaterial = bubbles.process_material

signal speed_changed(speed: float)

func _ready() -> void:
	# One-time particle defaults
	if bubbles_mat:
		# gentle upward drift so bubbles feel watery
		bubbles_mat.gravity = Vector3(0.0, -15.0, 0.0)
		# slight base direction to the left (overridden each frame by velocity)
		bubbles_mat.direction = Vector3(-1.0, 0.0, 0.0)
		# base spread and size
		bubbles_mat.spread = 45.0
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

	# --- Bubbles: dynamic emission + direction + size (Godot 4.3 properties) ---
	bubbles.emitting = speed > 10.0

	if bubbles_mat:
		# Direction opposite to movement (fallback left if almost stopped)
		var dir2: Vector2 = (-velocity.normalized()) if speed > 1.0 else Vector2.LEFT
		# direction is Vector3 in 4.3
		bubbles_mat.direction = Vector3(dir2.x, dir2.y, 0.0)

		# Map speed (0..300) → velocity (40..140), then give min/max wiggle
		var dyn_vel: float = lerp(40.0, 140.0, clamp(speed / 300.0, 0.0, 1.0))
		bubbles_mat.initial_velocity_min = max(0.0, dyn_vel * 0.85)
		bubbles_mat.initial_velocity_max = dyn_vel * 1.15

		# ✅ Nicety 1: bubble size scales a bit with speed (float min/max)
		var dyn_scale: float = lerp(0.45, 0.80, clamp(speed / 300.0, 0.0, 1.0))
		var smin: float = dyn_scale * 0.95
		var smax: float = dyn_scale * 1.05
		bubbles_mat.scale_min = smin
		bubbles_mat.scale_max = smax

		# ✅ Nicety 2: particle amount scales with speed (on node, not material)
		bubbles.amount = int(lerp(25.0, 90.0, clamp(speed / 300.0, 0.0, 1.0)))
