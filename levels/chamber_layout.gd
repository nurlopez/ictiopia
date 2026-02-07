extends Node2D

## Defines and spawns the organic chamber walls for Level 1.
## Three chambers (A, B, C) connected by two narrow passages.

const MembraneWallScene = preload("res://scenes/environment/membrane_wall.gd")

var wall_thickness: float = 10.0


func _ready() -> void:
	_spawn_chamber_a()
	_spawn_chamber_b()
	_spawn_chamber_c()


func _spawn_wall(points: PackedVector2Array) -> void:
	var wall := StaticBody2D.new()
	var script: GDScript = MembraneWallScene
	wall.set_script(script)
	wall.wall_points = points
	wall.wall_thickness = wall_thickness
	add_child(wall)


# ─── Chamber A (Entry) ───────────────────────────────────────────
# Upper-left region: ~(60,60) to ~(500,400)
# Player spawns here, Lightnode 1 is here.
# Open on the right side with a passage to Chamber B at y ~220-350.

func _spawn_chamber_a() -> void:
	# Top wall — gentle arc bulging upward
	_spawn_wall(PackedVector2Array([
		Vector2(60, 65),
		Vector2(150, 55),
		Vector2(280, 50),
		Vector2(400, 55),
		Vector2(500, 65),
	]))

	# Left wall — slight inward curve
	_spawn_wall(PackedVector2Array([
		Vector2(60, 65),
		Vector2(55, 130),
		Vector2(50, 230),
		Vector2(55, 330),
		Vector2(60, 395),
	]))

	# Bottom wall — organic curve
	_spawn_wall(PackedVector2Array([
		Vector2(60, 395),
		Vector2(150, 405),
		Vector2(280, 410),
		Vector2(400, 405),
		Vector2(500, 395),
	]))

	# Right wall — upper segment (above passage 1)
	_spawn_wall(PackedVector2Array([
		Vector2(500, 65),
		Vector2(505, 110),
		Vector2(510, 155),
		Vector2(512, 200),
	]))

	# Right wall — lower segment (below passage 1)
	_spawn_wall(PackedVector2Array([
		Vector2(512, 330),
		Vector2(510, 355),
		Vector2(505, 375),
		Vector2(500, 395),
	]))


# ─── Chamber B (Central) ─────────────────────────────────────────
# Upper-right region: ~(600,80) to ~(1060,430)
# Lightnode 2 is here. Connected to A via passage at left,
# and to C via passage at bottom-center.

func _spawn_chamber_b() -> void:
	# Top wall — wide organic arc
	_spawn_wall(PackedVector2Array([
		Vector2(600, 90),
		Vector2(700, 80),
		Vector2(830, 75),
		Vector2(950, 80),
		Vector2(1060, 90),
	]))

	# Left wall — upper segment (connects to passage 1 from A)
	_spawn_wall(PackedVector2Array([
		Vector2(600, 90),
		Vector2(598, 130),
		Vector2(595, 170),
		Vector2(593, 200),
	]))

	# Left wall — lower segment (below passage 1)
	_spawn_wall(PackedVector2Array([
		Vector2(593, 330),
		Vector2(595, 360),
		Vector2(598, 395),
		Vector2(600, 425),
	]))

	# Right wall — full height
	_spawn_wall(PackedVector2Array([
		Vector2(1060, 90),
		Vector2(1065, 160),
		Vector2(1068, 260),
		Vector2(1065, 350),
		Vector2(1060, 425),
	]))

	# Bottom wall — left segment (left of passage 2)
	_spawn_wall(PackedVector2Array([
		Vector2(600, 425),
		Vector2(660, 432),
		Vector2(730, 435),
		Vector2(770, 432),
	]))

	# Bottom wall — right segment (right of passage 2)
	_spawn_wall(PackedVector2Array([
		Vector2(900, 432),
		Vector2(950, 435),
		Vector2(1010, 432),
		Vector2(1060, 425),
	]))


# ─── Chamber C (Exit) ────────────────────────────────────────────
# Lower-right region: ~(650,510) to ~(1120,680)
# Lightnode 3 and Portal are here.

func _spawn_chamber_c() -> void:
	# Top wall — left segment (left of passage 2)
	_spawn_wall(PackedVector2Array([
		Vector2(650, 510),
		Vector2(710, 505),
		Vector2(770, 502),
	]))

	# Top wall — right segment (right of passage 2)
	_spawn_wall(PackedVector2Array([
		Vector2(900, 502),
		Vector2(960, 505),
		Vector2(1020, 508),
		Vector2(1120, 510),
	]))

	# Left wall
	_spawn_wall(PackedVector2Array([
		Vector2(650, 510),
		Vector2(645, 560),
		Vector2(642, 620),
		Vector2(645, 660),
		Vector2(650, 680),
	]))

	# Bottom wall — organic curve
	_spawn_wall(PackedVector2Array([
		Vector2(650, 680),
		Vector2(750, 688),
		Vector2(880, 690),
		Vector2(1000, 688),
		Vector2(1120, 680),
	]))

	# Right wall
	_spawn_wall(PackedVector2Array([
		Vector2(1120, 510),
		Vector2(1125, 560),
		Vector2(1128, 620),
		Vector2(1125, 660),
		Vector2(1120, 680),
	]))
