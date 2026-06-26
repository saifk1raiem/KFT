extends Button
class_name UnitCard

signal buy_requested(unit_id: StringName)

var unit_definition: UnitDefinition

func _ready() -> void:
	custom_minimum_size = Vector2(174, 110)
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

	var prefix := "UNLOCK " if unit_definition.unlockable else ""
	text = "%s%s\n%dG %s / %s\nHP %d  ATK %d  RNG %d" % [
		prefix,
		unit_definition.short_name(18),
		unit_definition.cost,
		String(unit_definition.origin),
		primary_class,
		unit_definition.max_health,
		unit_definition.attack_damage,
		unit_definition.attack_range
	]
	_apply_card_style(unit_definition.cost)
	var unlock_text := ""
	if unit_definition.unlockable:
		unlock_text = "\nUnlocked by: %s" % unit_definition.unlock_label
	tooltip_text = "%s\n%s%s\nStrengths: %s\nWeaknesses: %s" % [
		unit_definition.role,
		unit_definition.description,
		unlock_text,
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


func _apply_card_style(cost: int) -> void:
	var colors := {
		1: Color(0.18, 0.22, 0.24, 1.0),
		2: Color(0.12, 0.30, 0.20, 1.0),
		3: Color(0.12, 0.25, 0.42, 1.0),
		4: Color(0.33, 0.19, 0.44, 1.0),
		5: Color(0.54, 0.38, 0.12, 1.0)
	}
	var base_color: Color = colors.get(cost, Color(0.18, 0.22, 0.24, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = Color(1.0, 0.82, 0.30, 1.0) if unit_definition != null and unit_definition.unlockable else Color(0.82, 0.72, 0.48, 1.0)
	normal.set_border_width_all(3 if unit_definition != null and unit_definition.unlockable else 2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.14)
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = base_color.darkened(0.12)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_color_override("font_color", Color(1.0, 0.96, 0.84, 1.0))
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
