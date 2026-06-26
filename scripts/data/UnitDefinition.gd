extends Resource
class_name UnitDefinition

@export var id: StringName = &""
@export var display_name := ""
@export_range(1, 5, 1) var cost := 1
@export var origin: StringName = &""
@export var classes: Array[StringName] = []
@export var role := ""
@export_multiline var description := ""
@export var max_health := 100
@export var attack_damage := 10
@export var attack_range := 1
@export var attack_speed := 1.0
@export var armor := 0
@export var strengths: Array[String] = []
@export var weaknesses: Array[String] = []
@export var unlockable := false
@export var unlock_label := ""
@export var unlock_condition: Dictionary = {}

static func from_dictionary(data: Dictionary) -> UnitDefinition:
	var definition := UnitDefinition.new()
	definition.id = StringName(str(data.get("id", "")))
	definition.display_name = str(data.get("display_name", definition.id))
	definition.cost = int(data.get("cost", 1))
	definition.origin = StringName(str(data.get("origin", "")))
	definition.classes = _to_string_name_array(data.get("classes", []))
	definition.role = str(data.get("role", ""))
	definition.description = str(data.get("description", ""))
	definition.max_health = int(data.get("max_health", 100))
	definition.attack_damage = int(data.get("attack_damage", 10))
	definition.attack_range = int(data.get("attack_range", 1))
	definition.attack_speed = float(data.get("attack_speed", 1.0))
	definition.armor = int(data.get("armor", 0))
	definition.strengths = _to_string_array(data.get("strengths", []))
	definition.weaknesses = _to_string_array(data.get("weaknesses", []))
	definition.unlockable = bool(data.get("unlockable", false))
	definition.unlock_label = str(data.get("unlock_label", ""))
	if data.has("unlock_condition") and data["unlock_condition"] is Dictionary:
		definition.unlock_condition = data["unlock_condition"] as Dictionary
	return definition


func has_class(class_id: StringName) -> bool:
	return classes.has(class_id)


func trait_label() -> String:
	var label := String(origin)
	for class_id in classes:
		if not label.is_empty():
			label += " / "
		label += String(class_id)
	return label


func short_name(max_length: int = 18) -> String:
	if display_name.length() <= max_length:
		return display_name
	return display_name.substr(0, max_length - 1) + "."


static func _to_string_name_array(value: Variant) -> Array[StringName]:
	var output: Array[StringName] = []
	if value is Array:
		for item in value:
			output.append(StringName(str(item)))
	return output


static func _to_string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if value is Array:
		for item in value:
			output.append(str(item))
	return output
