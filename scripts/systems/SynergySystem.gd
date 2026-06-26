extends RefCounted
class_name SynergySystem

const TRAIT_BREAKPOINTS := {
	&"Militia": [3, 5, 7],
	&"Japanese": [2, 4],
	&"Mongol": [2, 4, 6],
	&"Norse": [2, 4],
	&"Frankish": [2, 4],
	&"English": [2, 4],
	&"Byzantine": [2, 4],
	&"Arab": [2, 4],
	&"Persian": [2, 4],
	&"Chinese": [2, 4],
	&"Ottoman": [2, 3],
	&"Phoenician": [2, 3],
	&"Infantry": [2, 4, 6],
	&"Guardian": [2, 4],
	&"Archer": [2, 4],
	&"Cavalry": [2, 4],
	&"Assassin": [2, 4],
	&"Duelist": [2, 4],
	&"Commander": [1, 2, 3],
	&"Siege": [1, 2],
	&"Skirmisher": [2, 4],
	&"Support": [2, 3],
	&"Spears": [2, 4]
}

static func calculate(units: Array[RuntimeUnit]) -> Dictionary:
	var counts: Dictionary = {}
	for unit: RuntimeUnit in units:
		if unit == null or unit.definition == null:
			continue
		_add_count(counts, unit.definition.origin)
		for class_id: StringName in unit.definition.classes:
			_add_count(counts, class_id)

	var active: Dictionary = {}
	for trait_key: Variant in counts.keys():
		var trait_id: StringName = StringName(trait_key)
		var reached: int = _reached_breakpoint(trait_id, int(counts[trait_id]))
		if reached > 0:
			active[trait_id] = reached

	return {
		"counts": counts,
		"active": active
	}


static func summary(units: Array[RuntimeUnit]) -> String:
	var result: Dictionary = calculate(units)
	var active: Dictionary = result["active"] as Dictionary
	if active.is_empty():
		return "No active doctrines"

	var parts: Array[String] = []
	for trait_key: Variant in active.keys():
		var trait_id: StringName = StringName(trait_key)
		parts.append("%s %d" % [String(trait_id), int(active[trait_id])])
	return _join_strings(parts, ", ")


static func _add_count(counts: Dictionary, trait_id: StringName) -> void:
	if String(trait_id).is_empty():
		return
	counts[trait_id] = int(counts.get(trait_id, 0)) + 1


static func _reached_breakpoint(trait_id: StringName, count: int) -> int:
	var breakpoints: Array = TRAIT_BREAKPOINTS.get(trait_id, []) as Array
	var reached: int = 0
	for threshold: Variant in breakpoints:
		if count >= int(threshold):
			reached = int(threshold)
	return reached


static func _join_strings(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output
