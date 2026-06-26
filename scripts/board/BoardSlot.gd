extends Button
class_name BoardSlot

signal slot_pressed(grid_position: Vector2i)

var grid_position := Vector2i.ZERO
var side: StringName = IronEnums.SIDE_PLAYER
var unit: RuntimeUnit

func _ready() -> void:
	custom_minimum_size = Vector2(112, 78)
	toggle_mode = false
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	_refresh()


func setup(new_position: Vector2i, new_side: StringName) -> void:
	grid_position = new_position
	side = new_side
	_refresh()


func set_unit(new_unit: RuntimeUnit) -> void:
	unit = new_unit
	_refresh()


func clear_unit() -> void:
	unit = null
	_refresh()


func _refresh() -> void:
	if unit == null:
		var label := "DEPLOY" if side == IronEnums.SIDE_PLAYER else "ENEMY"
		text = "%s\n%s" % [label, _cell_name()]
		_apply_style(_empty_color(), Color(0.93, 0.94, 0.9, 1.0))
		return

	text = "%s\nHP %d/%d" % [unit.display_label(12), unit.current_health, unit.max_health()]
	var color := Color(0.15, 0.42, 0.24, 1.0) if unit.side == IronEnums.SIDE_PLAYER else Color(0.50, 0.18, 0.15, 1.0)
	_apply_style(color, Color(1.0, 0.96, 0.86, 1.0))


func _on_pressed() -> void:
	slot_pressed.emit(grid_position)


func _cell_name() -> String:
	var letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	return "%s%d" % [letters.substr(grid_position.x, 1), grid_position.y + 1]


func _empty_color() -> Color:
	if side == IronEnums.SIDE_PLAYER:
		return Color(0.12, 0.22, 0.18, 1.0)
	return Color(0.24, 0.14, 0.13, 1.0)


func _apply_style(base_color: Color, font_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = Color(0.72, 0.66, 0.48, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.12)

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = base_color.darkened(0.12)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
