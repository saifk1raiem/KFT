extends Button
class_name UnitCard

signal buy_requested(unit_id: StringName)

var unit_definition: UnitDefinition

func _ready() -> void:
	custom_minimum_size = Vector2(156, 96)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)


func set_unit_definition(definition: UnitDefinition) -> void:
	unit_definition = definition
	if unit_definition == null:
		text = "Empty"
		disabled = true
		return

	var primary_class := "Soldier"
	if not unit_definition.classes.is_empty():
		primary_class = String(unit_definition.classes[0])

	text = "%s\n%dG  %s\n%s" % [
		unit_definition.short_name(18),
		unit_definition.cost,
		String(unit_definition.origin),
		primary_class
	]
	tooltip_text = "%s\n%s\nStrengths: %s\nWeaknesses: %s" % [
		unit_definition.role,
		unit_definition.description,
		_join_strings(unit_definition.strengths, ", "),
		_join_strings(unit_definition.weaknesses, ", ")
	]


func _on_pressed() -> void:
	if unit_definition != null:
		buy_requested.emit(unit_definition.id)


func _join_strings(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output
