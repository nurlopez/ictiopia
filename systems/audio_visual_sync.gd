extends Node
class_name AudioVisualSync

## Bridges audio intensity to visual effects.
## Routes audio pulse information to circuit network for rhythmic pulsing.

signal pulse_changed(pulse: float)

# References (set by NervousSystem)
var circuit_network: CircuitNetwork
var soundscape_manager: SoundscapeManager

# Pulse smoothing
@export var pulse_lerp_speed: float = 8.0
@export var pulse_decay: float = 3.0

var _current_pulse: float = 0.0
var _target_pulse: float = 0.0

# Optional spectrum analyzer (for more precise audio reactivity)
var _spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var _use_spectrum: bool = false


func _ready() -> void:
	_try_setup_spectrum_analyzer()


func _try_setup_spectrum_analyzer() -> void:
	# Try to get spectrum analyzer from Soundscape bus
	var bus_idx := AudioServer.get_bus_index("Soundscape")
	if bus_idx == -1:
		return

	# Look for spectrum analyzer effect
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, i)
			_use_spectrum = true
			print("[AudioVisualSync] Spectrum analyzer found")
			return


func _process(delta: float) -> void:
	if _use_spectrum:
		_update_from_spectrum()
	else:
		# Decay pulse naturally when no new input
		_target_pulse = maxf(0.0, _target_pulse - pulse_decay * delta)

	# Smooth the pulse value
	_current_pulse = lerpf(_current_pulse, _target_pulse, pulse_lerp_speed * delta)

	# Route to circuit network
	if circuit_network:
		circuit_network.on_audio_pulse(_current_pulse)

	pulse_changed.emit(_current_pulse)


func _update_from_spectrum() -> void:
	if _spectrum_analyzer == null:
		return

	# Get bass frequencies (20-200 Hz) for pulse effect
	var bass := _spectrum_analyzer.get_magnitude_for_frequency_range(20.0, 200.0)
	var bass_magnitude := (bass.x + bass.y) / 2.0

	# Convert to linear scale and normalize
	var bass_db: float = linear_to_db(bass_magnitude)
	var normalized_bass: float = clampf((bass_db + 60.0) / 60.0, 0.0, 1.0)

	_target_pulse = normalized_bass


func on_audio_intensity_changed(intensity: float) -> void:
	# Fallback when spectrum analyzer not available
	# Use overall intensity with some variation
	if not _use_spectrum:
		_target_pulse = intensity * 0.8


func setup(network: CircuitNetwork, soundscape: SoundscapeManager) -> void:
	circuit_network = network
	soundscape_manager = soundscape

	# Connect to soundscape intensity signal
	if soundscape_manager:
		soundscape_manager.audio_intensity_changed.connect(on_audio_intensity_changed)
