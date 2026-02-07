extends Control

## Lightnode progress — shows actual lightnode icons that light up when fixed.

@export var icon_size: float = 28.0
@export var spacing: float = 22.0
@export var dim_color: Color = Color(0.015, 0.022, 0.171, 0.6)
@export var lit_color: Color = Color(0.952941, 0.027451, 0.043137, 1.0)
@export var glow_color: Color = Color(0.952941, 0.027451, 0.043137, 0.2)

var _lightnode_data: Array = []  # [{texture, is_fixed}]


func _ready() -> void:
	# Wait a frame so lightnodes are in the tree
	await get_tree().process_frame
	_discover_lightnodes()


func _discover_lightnodes() -> void:
	var nodes := get_tree().get_nodes_in_group("lightnodes")
	_lightnode_data.clear()
	for n in nodes:
		var tex: Texture2D = n.get("icon") if n else null
		_lightnode_data.append({"node": n, "texture": tex, "is_fixed": false})
	queue_redraw()


func update_progress() -> void:
	for entry in _lightnode_data:
		var n = entry["node"]
		if n and is_instance_valid(n):
			entry["is_fixed"] = n.get("_is_fixed") == true
	queue_redraw()


func _draw() -> void:
	if _lightnode_data.size() == 0:
		return

	var total: int = _lightnode_data.size()
	var total_width: float = float(total) * icon_size + float(total - 1) * (spacing - icon_size)
	var start_x: float = (size.x - total_width) * 0.5
	var center_y: float = size.y * 0.5
	var t := float(Time.get_ticks_msec()) / 1000.0

	for i in range(total):
		var entry: Dictionary = _lightnode_data[i]
		var tex: Texture2D = entry["texture"]
		var is_fixed: bool = entry["is_fixed"]

		var x: float = start_x + float(i) * spacing
		var pos := Vector2(x, center_y - icon_size * 0.5)
		var icon_rect := Rect2(pos, Vector2(icon_size, icon_size))

		if tex:
			if is_fixed:
				# Round glow halo behind lit icon
				var pulse: float = 1.0 + sin(t * 1.8 + float(i) * 1.2) * 0.1
				var halo_radius: float = icon_size * 0.6 * pulse
				var icon_center := pos + Vector2(icon_size, icon_size) * 0.5
				draw_circle(icon_center, halo_radius, glow_color)
				draw_texture_rect(tex, icon_rect, false, lit_color)
			else:
				draw_texture_rect(tex, icon_rect, false, dim_color)
