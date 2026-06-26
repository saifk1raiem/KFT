extends Node2D
class_name UnitPawn

@export var radius := 24.0

var runtime_unit: RuntimeUnit

func set_runtime_unit(unit: RuntimeUnit) -> void:
	runtime_unit = unit
	queue_redraw()


func _draw() -> void:
	var color := Color(0.35, 0.75, 0.45, 1.0)
	if runtime_unit != null and runtime_unit.side == IronEnums.SIDE_ENEMY:
		color = Color(0.9, 0.35, 0.28, 1.0)
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius, Color(0.08, 0.08, 0.08, 1.0), false, 2.0)

