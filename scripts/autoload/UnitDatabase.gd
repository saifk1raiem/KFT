extends Node

const UNIT_DATA_PATHS: Array[String] = [
	"res://data/units/iron_draft_units.json",
	"res://data/units/iron_draft_unlockables.json"
]

signal loaded(unit_count: int)

var rng := RandomNumberGenerator.new()
var _units: Array[UnitDefinition] = []
var _base_units: Array[UnitDefinition] = []
var _unlockable_units: Array[UnitDefinition] = []
var _units_by_id: Dictionary = {}

func _ready() -> void:
	rng.randomize()
	reload()


func reload() -> void:
	_units.clear()
	_base_units.clear()
	_unlockable_units.clear()
	_units_by_id.clear()

	for path: String in UNIT_DATA_PATHS:
		_load_unit_file(path)

	_units.sort_custom(_sort_units_by_cost)
	_base_units.sort_custom(_sort_units_by_cost)
	_unlockable_units.sort_custom(_sort_units_by_cost)
	loaded.emit(_units.size())


func _load_unit_file(path: String) -> void:
	var file_text := FileAccess.get_file_as_string(path)
	if file_text.is_empty():
		push_error("UnitDatabase could not read %s" % path)
		return

	var parsed: Variant = JSON.parse_string(file_text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("UnitDatabase expected an array in %s" % path)
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
		if definition.unlockable:
			_unlockable_units.append(definition)
		else:
			_base_units.append(definition)
		_units_by_id[definition.id] = definition


func all_units() -> Array[UnitDefinition]:
	var copy: Array[UnitDefinition] = []
	copy.append_array(_units)
	return copy


func base_units() -> Array[UnitDefinition]:
	var copy: Array[UnitDefinition] = []
	copy.append_array(_base_units)
	return copy


func unlockable_units() -> Array[UnitDefinition]:
	var copy: Array[UnitDefinition] = []
	copy.append_array(_unlockable_units)
	return copy


func unlockable_count() -> int:
	return _unlockable_units.size()


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


func base_units_for_cost(cost: int) -> Array[UnitDefinition]:
	var matches: Array[UnitDefinition] = []
	for unit in _base_units:
		if unit.cost == cost:
			matches.append(unit)
	return matches


func unlockable_units_for_cost(cost: int) -> Array[UnitDefinition]:
	var matches: Array[UnitDefinition] = []
	for unit in _unlockable_units:
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
		var pool: Array[UnitDefinition] = base_units_for_cost(cost)
		if pool.is_empty():
			pool = base_units()
		rolls.append(pool[rng.randi_range(0, pool.size() - 1)])
	return rolls


func roll_personal_shop(level: int, size: int, unlock_system: UnlockSystem) -> Array[UnitDefinition]:
	var rolls: Array[UnitDefinition] = []
	var odds: Dictionary = IronEnums.shop_odds_for_level(level)
	for index: int in range(size):
		var cost: int = _weighted_cost(odds)
		var pool: Array[UnitDefinition] = base_units_for_cost(cost)
		var unlock_pool: Array[UnitDefinition] = unlockable_units_for_cost(cost)
		for unlock_unit: UnitDefinition in unlock_pool:
			if unlock_system != null and unlock_system.is_unlocked(unlock_unit.id):
				var chance: float = unlock_system.appearance_multiplier(unlock_unit.id)
				if rng.randf() <= chance:
					pool.append(unlock_unit)
		if pool.is_empty():
			pool = base_units()
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
