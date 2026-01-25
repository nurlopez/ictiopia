extends Label

@onready var lc := $"../../LevelController"

func _process(_delta: float) -> void:
	if lc:
		text = "Stress: %.1f / %.0f" % [lc.stress, lc.stress_limit]
