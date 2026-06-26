extends RefCounted
class_name RuntimeUnit

static var _next_instance_id := 1

var instance_id := 0
var definition: UnitDefinition
var side: StringName = IronEnums.SIDE_PLAYER
var star_level := 1
var current_health := 1
var board_position := Vector2i(-1, -1)
var bonus_health := 0
var bonus_damage := 0
var bonus_armor := 0

func _init(unit_definition: UnitDefinition = null, unit_side: StringName = IronEnums.SIDE_PLAYER) -> void:
	instance_id = _next_instance_id
	_next_instance_id += 1
	side = unit_side
	if unit_definition != null:
		configure(unit_definition)


func configure(unit_definition: UnitDefinition) -> void:
	definition = unit_definition
	current_health = max_health()


func max_health() -> int:
	if definition == null:
		return 1
	return int(float(definition.max_health + bonus_health) * (1.0 + 0.8 * float(star_level - 1)))


func attack_damage() -> int:
	if definition == null:
		return 1
	return int(float(definition.attack_damage + bonus_damage) * (1.0 + 0.55 * float(star_level - 1)))


func armor() -> int:
	if definition == null:
		return 0
	return definition.armor + bonus_armor


func clear_combat_modifiers() -> void:
	bonus_health = 0
	bonus_damage = 0
	bonus_armor = 0


func start_combat() -> void:
	current_health = max_health()


func receive_damage(amount: int) -> void:
	current_health = maxi(0, current_health - maxi(1, amount))


func is_alive() -> bool:
	return current_health > 0


func display_label(max_length: int = 15) -> String:
	if definition == null:
		return "Empty"
	return "%s %d*" % [definition.short_name(max_length), star_level]
