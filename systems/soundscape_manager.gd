extends Node
class_name SoundscapeManager

## Manages 4 layered audio streams that crossfade based on stress level.
## Creates an evolving soundscape reflecting the nervous system state.

signal audio_intensity_changed(intensity: float)

# Audio paths
const CALM_AUDIO := "res://assets/audio/calm.mp3"
const NEUTRAL_AUDIO := "res://assets/audio/distant-signal-drone-74016.mp3"
const TENSE_AUDIO := "res://assets/audio/tension.mp3"
const STRESS_AUDIO := "res://assets/audio/weird-pulse-sonar-sound-64566.mp3"

# Audio players (created at runtime)
var _calm_player: AudioStreamPlayer
var _neutral_player: AudioStreamPlayer
var _tense_player: AudioStreamPlayer
var _stress_player: AudioStreamPlayer

# Volume ranges for each layer based on stress (in dB)
# [stress_min, stress_max, volume_at_min, volume_at_max]
const LAYER_RANGES := {
	"calm": [0.0, 0.3, 0.0, -20.0],      # Full volume at 0 stress, fade out by 0.3
	"neutral": [0.0, 0.6, -10.0, -6.0],  # Subtle throughout, peaks mid-range
	"tense": [0.2, 0.8, -30.0, -3.0],    # Builds from 0.2, loud at 0.8
	"stress": [0.5, 1.0, -25.0, -2.0]    # Only audible above 0.5, dominant at max
}

# Pitch scaling for tense layer (heartbeat speeds up with stress)
@export var tense_pitch_min: float = 0.8
@export var tense_pitch_max: float = 1.4

# Crossfade smoothing
@export var volume_lerp_speed: float = 2.0

# Target volumes (lerped toward)
var _target_volumes := {
	"calm": 0.0,
	"neutral": -10.0,
	"tense": -30.0,
	"stress": -25.0
}

var _current_stress: float = 0.0


func _ready() -> void:
	_create_audio_players()
	_start_playback()


func _create_audio_players() -> void:
	_calm_player = _create_player(CALM_AUDIO, "calm")
	_neutral_player = _create_player(NEUTRAL_AUDIO, "neutral")
	_tense_player = _create_player(TENSE_AUDIO, "tense")
	_stress_player = _create_player(STRESS_AUDIO, "stress")


func _create_player(audio_path: String, layer_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)

	var stream := load(audio_path) as AudioStream
	if stream:
		player.stream = stream
		# Use Soundscape bus if it exists, otherwise fall back to Master
		var bus_idx := AudioServer.get_bus_index("Soundscape")
		if bus_idx >= 0:
			player.bus = "Soundscape"
		else:
			player.bus = "Master"
	else:
		push_warning("[SoundscapeManager] Could not load audio: ", audio_path)

	# Start at minimum volume
	var range_data: Array = LAYER_RANGES[layer_name]
	player.volume_db = range_data[2] if range_data[2] < range_data[3] else range_data[3]
	player.volume_db = minf(player.volume_db, -30.0)  # Ensure starts quiet

	return player


func _start_playback() -> void:
	# Start all layers playing (volume controls mix)
	for player in [_calm_player, _neutral_player, _tense_player, _stress_player]:
		if player and player.stream:
			player.play()


func _process(delta: float) -> void:
	_update_volumes(delta)
	_update_tense_pitch()
	_emit_audio_intensity()


func _update_volumes(delta: float) -> void:
	var lerp_factor: float = volume_lerp_speed * delta

	_lerp_player_volume(_calm_player, float(_target_volumes["calm"]), lerp_factor)
	_lerp_player_volume(_neutral_player, float(_target_volumes["neutral"]), lerp_factor)
	_lerp_player_volume(_tense_player, float(_target_volumes["tense"]), lerp_factor)
	_lerp_player_volume(_stress_player, float(_target_volumes["stress"]), lerp_factor)


func _lerp_player_volume(player: AudioStreamPlayer, target_db: float, factor: float) -> void:
	if player == null:
		return
	player.volume_db = lerpf(player.volume_db, target_db, factor)


func _update_tense_pitch() -> void:
	if _tense_player == null:
		return
	# Pitch up the heartbeat as stress increases
	var pitch: float = lerpf(tense_pitch_min, tense_pitch_max, _current_stress)
	_tense_player.pitch_scale = pitch


func _emit_audio_intensity() -> void:
	# Calculate overall audio intensity for visual sync
	# Weight toward the more dramatic layers when they're audible
	var calm_contrib: float = _db_to_linear(_calm_player.volume_db if _calm_player else -80.0) * 0.3
	var neutral_contrib: float = _db_to_linear(_neutral_player.volume_db if _neutral_player else -80.0) * 0.4
	var tense_contrib: float = _db_to_linear(_tense_player.volume_db if _tense_player else -80.0) * 0.8
	var stress_contrib: float = _db_to_linear(_stress_player.volume_db if _stress_player else -80.0) * 1.0

	var intensity: float = (calm_contrib + neutral_contrib + tense_contrib + stress_contrib) / 2.5
	intensity = clampf(intensity, 0.0, 1.0)

	audio_intensity_changed.emit(intensity)


func _db_to_linear(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return pow(10.0, db / 20.0)


func on_stress_changed(stress: float) -> void:
	_current_stress = stress
	_calculate_target_volumes(stress)


func _calculate_target_volumes(stress: float) -> void:
	for layer_name in LAYER_RANGES.keys():
		var range_data: Array = LAYER_RANGES[layer_name]
		var stress_min: float = range_data[0]
		var stress_max: float = range_data[1]
		var vol_at_min: float = range_data[2]
		var vol_at_max: float = range_data[3]

		var target_vol: float
		if stress < stress_min:
			# Below range - use minimum volume (which might be silent)
			target_vol = minf(vol_at_min, vol_at_max) - 20.0  # Extra quiet
		elif stress > stress_max:
			# Above range - start fading out
			var fade: float = (stress - stress_max) / (1.0 - stress_max + 0.001)
			target_vol = lerpf(maxf(vol_at_min, vol_at_max), -40.0, fade)
		else:
			# Within range - interpolate
			var t: float = (stress - stress_min) / (stress_max - stress_min + 0.001)
			target_vol = lerpf(vol_at_min, vol_at_max, t)

		_target_volumes[layer_name] = target_vol


func restart_playback() -> void:
	_start_playback()
