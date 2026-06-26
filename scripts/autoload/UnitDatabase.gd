extends Node

const UNIT_DATA_PATH := "res://data/units/iron_draft_units.json"

signal loaded(unit_count: int)

var rng := RandomNumberGenerator.new()
var _units: Array[UnitDefinition] = []
var _units_by_id: Dictionary = {}

func _ready() -> void:
	rng.randomize()
	reload()


func reload() -> void:
	_units.clear()
	_units_by_id.clear()

	var file_text := FileAccess.get_file_as_string(UNIT_DATA_PATH)
	if file_text.is_empty():
		push_error("UnitDatabase could not read %s" % UNIT_DATA_PATH)
		return

	var parsed: Variant = JSON.parse_string(file_text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("UnitDatabase expected an array in %s" % UNIT_DATA_PATH)
		return

	var rows: Array = parsed as Array
	for row: Variant in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row as Dictionary
		var definition: UnitDefinition = UnitDefinition.from_dictionary(row_data)
		if String(definition.id).is_empty():
			continue
		_units.append(definition)
		_units_by_id[definition.id] = definition

	_units.sort_custom(_sort_units_by_cost)
	loaded.emit(_units.size())


func all_units() -> Array[UnitDefinition]:
	var copy: Array[UnitDefinition] = []
	copy.append_array(_units)
	return copy


func get_unit(unit_id: StringName) -> UnitDefinition:
	if _units_by_id.has(unit_id):
		return _units_by_id[unit_id] as UnitDefinition
	return null


func units_for_cost(cost: int) -> Array[UnitDefinition]:
	var matches: Array[UnitDefinition] = []
	for unit in _units:
		if unit.cost == cost:
			matches.append(unit)
	return matches


func roll_shop(level: int, size: int = 5) -> Array[UnitDefinition]:
	var rolls: Array[UnitDefinition] = []
	if _units.is_empty():
		return rolls

	var odds: Dictionary = IronEnums.shop_odds_for_level(level)
	for index: int in range(size):
		var cost: int = _weighted_cost(odds)
		var pool: Array[UnitDefinition] = units_for_cost(cost)
		if pool.is_empty():
			pool = all_units()
		rolls.append(pool[rng.randi_range(0, pool.size() - 1)])
	return rolls


func _weighted_cost(odds: Dictionary) -> int:
	var total: int = 0
	for weight: Variant in odds.values():
		total += int(weight)
	if total <= 0:
		return 1

	var roll: int = rng.randi_range(1, total)
	var cursor: int = 0
	for cost_key: Variant in odds.keys():
		var cost: int = int(cost_key)
		cursor += int(odds[cost])
		if roll <= cursor:
			return cost
	return 1


func _sort_units_by_cost(a: UnitDefinition, b: UnitDefinition) -> bool:
	if a.cost == b.cost:
		return a.display_name < b.display_name
	return a.cost < b.cost
