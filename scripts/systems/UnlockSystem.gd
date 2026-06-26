extends RefCounted
class_name UnlockSystem

signal unit_unlocked(unit: UnitDefinition)

var unlocked_ids: Dictionary = {}
var ignored_counts: Dictionary = {}
var pending_ids: Array[StringName] = []
var current_rightmost_id: StringName = &""
var current_rightmost_bought := false

func reset() -> void:
	unlocked_ids.clear()
	ignored_counts.clear()
	pending_ids.clear()
	current_rightmost_id = &""
	current_rightmost_bought = false


func is_unlocked(unit_id: StringName) -> bool:
	return bool(unlocked_ids.get(unit_id, false))


func unlocked_count() -> int:
	return unlocked_ids.size()


func appearance_multiplier(unit_id: StringName) -> float:
	var ignored: int = int(ignored_counts.get(unit_id, 0))
	return maxf(0.2, 1.0 - 0.2 * float(ignored))


func begin_roll() -> void:
	if not String(current_rightmost_id).is_empty() and not current_rightmost_bought:
		ignored_counts[current_rightmost_id] = int(ignored_counts.get(current_rightmost_id, 0)) + 1
	current_rightmost_id = &""
	current_rightmost_bought = false


func next_rightmost_offer() -> UnitDefinition:
	if pending_ids.is_empty():
		return null

	var unit_id: StringName = pending_ids.pop_front()
	var definition: UnitDefinition = UnitDatabase.get_unit(unit_id)
	if definition == null:
		return null
	return definition


func mark_offer_shown(unit_id: StringName) -> void:
	current_rightmost_id = unit_id
	current_rightmost_bought = false


func mark_offer_bought(unit_id: StringName) -> void:
	if unit_id == current_rightmost_id:
		current_rightmost_bought = true
	ignored_counts[unit_id] = 0


func evaluate_unlocks(context: Dictionary) -> Array[UnitDefinition]:
	var newly_unlocked: Array[UnitDefinition] = []
	for definition: UnitDefinition in UnitDatabase.unlockable_units():
		if is_unlocked(definition.id):
			continue
		if _condition_met(definition.unlock_condition, context):
			unlocked_ids[definition.id] = true
			pending_ids.append(definition.id)
			newly_unlocked.append(definition)
			unit_unlocked.emit(definition)
	return newly_unlocked


func summary() -> String:
	var total: int = UnitDatabase.unlockable_count()
	var pending_text: String = "none"
	if not pending_ids.is_empty():
		var names: Array[String] = []
		for unit_id: StringName in pending_ids:
			var definition: UnitDefinition = UnitDatabase.get_unit(unit_id)
			if definition != null:
				names.append(definition.short_name(16))
		pending_text = _join_strings(names, ", ")
	return "Unlocks: %d/%d | Pending right slot: %s" % [unlocked_count(), total, pending_text]


func _condition_met(condition: Dictionary, context: Dictionary) -> bool:
	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"trait_count":
			var trait_id: StringName = StringName(str(condition.get("trait", "")))
			var required_count: int = int(condition.get("count", 0))
			var traits: Dictionary = context.get("traits", {}) as Dictionary
			return int(traits.get(trait_id, 0)) >= required_count
		"deployed_count":
			return int(context.get("deployed_count", 0)) >= int(condition.get("count", 0))
		"level":
			return int(context.get("level", 1)) >= int(condition.get("level", 1))
		"round":
			return int(context.get("round", 1)) >= int(condition.get("round", 1))
		"gold":
			return int(context.get("gold", 0)) >= int(condition.get("amount", 0))
		"wins":
			return int(context.get("wins", 0)) >= int(condition.get("count", 0))
		_:
			return false


func _join_strings(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output
