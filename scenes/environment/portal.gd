extends Area2D

@export var start_hidden: bool = true
@export var accepts_player: bool = false  # locked until calm mode
@export var on_enter_fade_time: float = 0.6
@export var open_sound: AudioStream
@export var enter_sound: AudioStream

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# Connect body_entered
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	# Initial visual state
	if start_hidden:
		modulate.a = 0.0
		shape.set_deferred("disabled", true)
		accepts_player = false
		anim.stop()
	else:
		if anim.has_animation("idle"):
			anim.play("idle")

func open_portal() -> void:
	# Called by LevelController when calm mode starts
	accepts_player = true
	shape.set_deferred("disabled", false)
	# Play open anim + sound
	if anim.has_animation("open"):
		anim.play("open")
		await anim.animation_finished
	if anim.has_animation("idle"):
		anim.play("idle")

	if open_sound:
		audio.stream = open_sound
		audio.volume_db = -6.0
		audio.play()

	# Fade in if hidden
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)

func _on_body_entered(body: Node) -> void:
	if not accepts_player:
		return
	if body == null or body.name != "Ictio":
		return

	# Optional enter sound
	if enter_sound:
		audio.stream = enter_sound
		audio.volume_db = -6.0
		audio.play()

	# Gentle fade-out (end-of-level placeholder)
	var tween := create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, on_enter_fade_time)
	await tween.finished

	# Placeholder end action: restart level (you can replace with a next-level load)
	get_tree().reload_current_scene()
