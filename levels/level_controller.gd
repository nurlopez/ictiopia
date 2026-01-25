extends Node

## --- Tunables (adjust in Inspector) ---

@export var stress_limit: float = 100.0 
@export var overspeed_power: float = 2.0      # non-linearity; 2 = quadratic, 3 = cubic
@export var overspeed_gain: float = 0.02      # lower than before; we’ll square the over-speed
@export var calm_decay: float = 1.4           # a bit stronger decay feels readable
	 # Max stress before fully intense
@export var overspeed_threshold: float = 120.0

@export var calm_color: Color = Color(0.76, 0.93, 1.00) # calm blue
@export var intense_color: Color = Color(0.173, 0.184, 0.243) # dark

var stress_view: float = 0.0                 # smoothed for visuals/audio
@export var view_lerp_speed: float = 6.0     # larger = faster catch-up, try 4–8
@export var tint_gamma: float = 2.0          # >1 makes early changes subtle; 2–3 feels “menacing”

## --- Node references (auto-wired on _ready) ---
@onready var tint := %Tint   # CanvasModulate
@onready var audio_player: AudioStreamPlayer = %Audio

@warning_ignore("UNUSED_SIGNAL")
signal all_collectibles_cleared


var stress: float = 0.0
var calm_mode: bool = false
var remaining_collectibles: int = 0
var started_with_collectibles := false


func _ready() -> void:
	# Connect 'all_collectibles_cleared' to the portal
	var portal := %Portal
	if portal and not is_connected("all_collectibles_cleared", Callable(portal, "open_portal")):
		connect("all_collectibles_cleared", Callable(portal, "open_portal"))

	# connect ictio
	var ictio := %Ictio
	if ictio:
		var cb := Callable(self, "_on_ictio_speed_changed")
		if not ictio.speed_changed.is_connected(cb):
			ictio.speed_changed.connect(cb)

	if audio_player and not audio_player.playing:
		audio_player.play()

	# Defer the collectible count so every Collectible has time to add_to_group()
	call_deferred("_late_count_collectibles")

	_apply_visuals() # initial calm visuals

	

# This will be called from Ictio via a signal we connect next
func _on_ictio_speed_changed(speed: float) -> void:
	if calm_mode:
		return

	if speed > overspeed_threshold:
		var over := (speed / overspeed_threshold) - 1.0    # 0.0 at threshold, rising above
		var growth := pow(over, overspeed_power)           # quadratic/cubic shape
		stress += growth * overspeed_gain * stress_limit   # scale to limit so values are meaningful
	else:
		stress = max(0.0, stress - calm_decay)

	stress = clamp(stress, 0.0, stress_limit)
	# do NOT call _apply_visuals() here anymore; visuals will be smoothed in _process()

func _process(delta: float) -> void:
	# time-based smoothing (1 - e^{-k*dt})
	var a := 1.0 - exp(-view_lerp_speed * delta)
	stress_view = lerp(stress_view, stress, a)
	_apply_visuals()

func reduce_stress(amount: float) -> void:
	stress = max(0.0, stress - amount)
	_apply_visuals()

func _late_count_collectibles() -> void:
	remaining_collectibles = get_tree().get_nodes_in_group("collectibles").size()
	started_with_collectibles = remaining_collectibles > 0
	print("[LevelController] found collectibles:", remaining_collectibles)

func notify_collectible_picked() -> void:
	remaining_collectibles = max(0, remaining_collectibles - 1)
	if started_with_collectibles and remaining_collectibles == 0:
		enter_calm_mode()

func _apply_visuals() -> void:
	var x: float = clamp(stress_view / stress_limit, 0.0, 1.0)
	var t := pow(x, tint_gamma)                       # subtle at low stress, faster near high
	var calm := calm_color                  # deep calm water
	var intense := intense_color              # warm-magenta stress
	if tint:
		tint.color = calm.lerp(intense, t)
	if audio_player:
		audio_player.volume_db = lerp(-20.0, -4.0, t)  # starts quiet, rises smoothly

func enter_calm_mode() -> void:
	calm_mode = true
	stress = 0.0
	_apply_visuals()
	if audio_player:
		audio_player.volume_db = -20.0
	emit_signal("all_collectibles_cleared")
