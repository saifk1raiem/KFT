extends RefCounted
class_name ArmyRoster

signal changed()

const BENCH_SIZE := 9

var bench: Array = []
var board: Dictionary = {}

func _init() -> void:
	bench.resize(BENCH_SIZE)


func has_open_bench_slot() -> bool:
	for unit in bench:
		if unit == null:
			return true
	return false


func add_to_bench(unit: RuntimeUnit) -> bool:
	for index in range(BENCH_SIZE):
		if bench[index] == null:
			bench[index] = unit
			unit.board_position = Vector2i(-1, -1)
			changed.emit()
			GameEvents.bench_changed.emit()
			return true
	return false


func deploy_from_bench(index: int, position: Vector2i) -> bool:
	if index < 0 or index >= bench.size() or bench[index] == null:
		return false

	var incoming: RuntimeUnit = bench[index] as RuntimeUnit
	if board.has(position):
		var existing: RuntimeUnit = board[position] as RuntimeUnit
		bench[index] = existing
		existing.board_position = Vector2i(-1, -1)
	else:
		bench[index] = null

	board[position] = incoming
	incoming.board_position = position
	changed.emit()
	GameEvents.bench_changed.emit()
	GameEvents.board_changed.emit()
	return true


func return_board_unit_to_bench(position: Vector2i) -> bool:
	if not board.has(position) or not has_open_bench_slot():
		return false
	var unit: RuntimeUnit = board[position] as RuntimeUnit
	board.erase(position)
	return add_to_bench(unit)


func get_deployed_units(side: StringName = IronEnums.SIDE_PLAYER) -> Array[RuntimeUnit]:
	var units: Array[RuntimeUnit] = []
	for board_unit: Variant in board.values():
		var unit: RuntimeUnit = board_unit as RuntimeUnit
		if unit != null and unit.side == side:
			units.append(unit)
	return units


func deployed_count() -> int:
	return board.size()
