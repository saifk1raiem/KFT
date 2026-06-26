extends Button
class_name BoardSlot

signal slot_pressed(grid_position: Vector2i)

var grid_position := Vector2i.ZERO
var side: StringName = IronEnums.SIDE_PLAYER
var unit: RuntimeUnit

func _ready() -> void:
	custom_minimum_size = Vector2(88, 74)
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
		var label := "Deploy" if side == IronEnums.SIDE_PLAYER else "Enemy"
		text = "%d,%d\n%s" % [grid_position.x + 1, grid_position.y + 1, label]
		modulate = Color(0.72, 0.74, 0.78, 1.0) if side == IronEnums.SIDE_PLAYER else Color(0.78, 0.66, 0.62, 1.0)
		return

	text = "%s\n%d/%d" % [unit.display_label(11), unit.current_health, unit.max_health()]
	modulate = Color(0.78, 0.93, 0.78, 1.0) if unit.side == IronEnums.SIDE_PLAYER else Color(0.96, 0.72, 0.68, 1.0)


func _on_pressed() -> void:
	slot_pressed.emit(grid_position)
