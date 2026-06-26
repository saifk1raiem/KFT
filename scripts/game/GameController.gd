extends VBoxContainer
class_name GameController

@onready var hud: HUD = $HUD
@onready var board: BattleBoard = $BattleBoard
@onready var combat_log_panel: Node = $CombatLogPanel
@onready var bench_panel: BenchPanel = $BenchPanel
@onready var shop_panel: ShopPanel = $ShopPanel

var economy := EconomySystem.new()
var shop := ShopSystem.new()
var roster := ArmyRoster.new()
var unlock_system := UnlockSystem.new()
var enemy_units: Array[RuntimeUnit] = []
var phase := IronEnums.GamePhase.PREP
var round_number := 1
var selected_bench_index := -1
var won_last_round := false
var player_health := 100
var rival_health := 100
var total_wins := 0
var total_losses := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("separation", 8)

	roster.changed.connect(_on_roster_changed)
	hud.start_battle_requested.connect(_start_battle)
	hud.end_round_requested.connect(_end_round)
	hud.refresh_shop_requested.connect(_refresh_shop_pressed)
	hud.buy_xp_requested.connect(_buy_xp_pressed)
	bench_panel.bench_slot_selected.connect(_select_bench_slot)
	shop_panel.unit_buy_requested.connect(_buy_unit)
	board.board_slot_pressed.connect(_on_board_slot_pressed)

	combat_log_panel.call("clear_log")
	_seed_opening_units()
	_evaluate_unlocks(false)
	_roll_shop(false)
	_refresh_all()


func _seed_opening_units() -> void:
	for unit_id in [&"barehand_recruit", &"light_archer"]:
		var definition := UnitDatabase.get_unit(unit_id)
		if definition == null:
			continue
		roster.add_to_bench(RuntimeUnit.new(definition, IronEnums.SIDE_PLAYER))

	roster.deploy_from_bench(0, Vector2i(3, 3))
	roster.deploy_from_bench(1, Vector2i(4, 3))


func _buy_unit(unit_id: StringName) -> void:
	if phase != IronEnums.GamePhase.PREP:
		_set_status("You can only buy during prep.")
		return

	var definition := UnitDatabase.get_unit(unit_id)
	if definition == null:
		_set_status("That unit is missing from the database.")
		return

	if not roster.has_open_bench_slot():
		_set_status("Bench is full.")
		return

	if not economy.spend(definition.cost):
		_set_status("Not enough gold for %s." % definition.display_name)
		return

	var unit := RuntimeUnit.new(definition, IronEnums.SIDE_PLAYER)
	roster.add_to_bench(unit)
	shop.remove_unit(unit_id, unlock_system)
	GameEvents.unit_bought.emit(unit)
	_set_status("Bought %s." % definition.display_name)
	_evaluate_unlocks(false)
	_refresh_all()


func _select_bench_slot(index: int) -> void:
	if phase != IronEnums.GamePhase.PREP:
		return
	if index < 0 or index >= roster.bench.size() or roster.bench[index] == null:
		selected_bench_index = -1
		bench_panel.clear_selection()
		return
	selected_bench_index = index
	bench_panel.select(index)
	_refresh_all()


func _on_board_slot_pressed(position: Vector2i) -> void:
	if phase != IronEnums.GamePhase.PREP:
		_set_status("Board changes are locked during combat/results.")
		return

	if not board.is_player_position(position):
		_set_status("Deploy on the lower half of the board.")
		return

	if selected_bench_index >= 0:
		if roster.deploy_from_bench(selected_bench_index, position):
			_set_status("Unit deployed.")
			_evaluate_unlocks(false)
		selected_bench_index = -1
		bench_panel.clear_selection()
	else:
		if roster.return_board_unit_to_bench(position):
			_set_status("Unit returned to bench.")
		else:
			_set_status("Select a bench unit first.")

	_refresh_all()


func _start_battle() -> void:
	if phase == IronEnums.GamePhase.COMBAT:
		return

	var deployed := roster.get_deployed_units()
	if deployed.is_empty():
		_set_status("Deploy at least one unit before battle.")
		return

	phase = IronEnums.GamePhase.COMBAT
	GameEvents.phase_changed.emit(phase)
	enemy_units = EnemyRosterBuilder.build(round_number, economy.level)
	board.sync_units(roster.board, enemy_units)
	combat_log_panel.call("clear_log")

	var result: Dictionary = CombatResolver.simulate(deployed, enemy_units)
	var result_log: Array = result["log"] as Array
	for line_value: Variant in result_log:
		var line := str(line_value)
		GameEvents.combat_log.emit(line)
		combat_log_panel.call("add_line", line)

	var winner: String = str(result["winner"])
	var exchanges: int = int(result["exchanges"])
	var player_alive: int = int(result["player_alive"])
	var enemy_alive: int = int(result["enemy_alive"])
	won_last_round = winner == "player"
	var health_message := _apply_player_damage(winner, player_alive, enemy_alive)
	phase = IronEnums.GamePhase.RESULTS
	GameEvents.phase_changed.emit(phase)

	if won_last_round:
		total_wins += 1
		economy.gain(2)
		_set_status("Victory after %d exchanges. Survived: %d vs %d. +2 gold. %s" % [exchanges, player_alive, enemy_alive, health_message])
		combat_log_panel.call("add_line", "Result: player victory.")
	elif winner == "enemy":
		total_losses += 1
		_set_status("Defeat after %d exchanges. Survived: %d vs %d. %s" % [exchanges, player_alive, enemy_alive, health_message])
		combat_log_panel.call("add_line", "Result: enemy victory.")
	else:
		_set_status("Draw after %d exchanges." % exchanges)
		combat_log_panel.call("add_line", "Result: draw.")

	_evaluate_unlocks(false)
	board.sync_units(roster.board, enemy_units)
	hud.set_doctrine("Active doctrines: %s" % SynergySystem.summary(roster.get_deployed_units()))
	_refresh_all()


func _end_round() -> void:
	if phase == IronEnums.GamePhase.COMBAT:
		return

	var income := economy.award_round_income(round_number, won_last_round)
	economy.add_xp(2)
	round_number += 1
	phase = IronEnums.GamePhase.PREP
	enemy_units.clear()
	selected_bench_index = -1
	bench_panel.clear_selection()
	_evaluate_unlocks(false)
	_roll_shop(false)
	for unit in roster.get_deployed_units():
		unit.clear_combat_modifiers()
		unit.start_combat()
	_set_status("Round income: %d gold. Prepare for round %d." % [income, round_number])
	GameEvents.phase_changed.emit(phase)
	_refresh_all()


func _refresh_shop_pressed() -> void:
	if phase != IronEnums.GamePhase.PREP:
		_set_status("Shop refresh is only available during prep.")
		return
	if not economy.spend(EconomySystem.SHOP_REFRESH_COST):
		_set_status("Not enough gold to refresh.")
		return
	_evaluate_unlocks(false)
	_roll_shop(false)
	_set_status("Shop refreshed.")
	_refresh_all()


func _buy_xp_pressed() -> void:
	if economy.buy_xp():
		_set_status("Bought XP.")
		_evaluate_unlocks(false)
	else:
		_set_status("Cannot buy XP right now.")
	_refresh_all()


func _roll_shop(spend_gold: bool) -> void:
	if spend_gold and not economy.spend(EconomySystem.SHOP_REFRESH_COST):
		return
	shop.roll(economy.level, unlock_system)


func _on_roster_changed() -> void:
	_refresh_all()


func _refresh_all() -> void:
	hud.update_state(economy.gold, economy.level, economy.xp, round_number, phase, player_health, rival_health, _stage_number())
	shop_panel.set_shop(shop.current_shop)
	bench_panel.set_units(roster.bench)
	board.sync_units(roster.board, enemy_units)
	hud.set_doctrine("Active doctrines: %s" % SynergySystem.summary(roster.get_deployed_units()))
	hud.set_unlocks(unlock_system.summary())


func _set_status(message: String) -> void:
	hud.set_status(message)
	GameEvents.status_message.emit(message)


func _evaluate_unlocks(show_status: bool = true) -> void:
	var newly_unlocked: Array[UnitDefinition] = unlock_system.evaluate_unlocks(_unlock_context())
	if newly_unlocked.is_empty():
		return

	var names: Array[String] = []
	for definition: UnitDefinition in newly_unlocked:
		names.append(definition.short_name(18))
		combat_log_panel.call("add_line", "Unlocked: %s. It will claim the right shop slot." % definition.display_name)

	if show_status:
		_set_status("Unlocked %s. Roll shop to see the right slot." % _join_strings(names, ", "))


func _unlock_context() -> Dictionary:
	var deployed: Array[RuntimeUnit] = roster.get_deployed_units()
	var synergy: Dictionary = SynergySystem.calculate(deployed)
	var trait_counts: Dictionary = synergy["counts"] as Dictionary
	return {
		"traits": trait_counts,
		"deployed_count": deployed.size(),
		"level": economy.level,
		"round": round_number,
		"gold": economy.gold,
		"wins": total_wins,
		"losses": total_losses
	}


func _apply_player_damage(winner: String, player_alive: int, enemy_alive: int) -> String:
	var base_damage: int = _stage_base_damage(_stage_number())
	if winner == "enemy":
		var damage_to_player: int = base_damage + enemy_alive
		player_health = maxi(0, player_health - damage_to_player)
		return "You took %d damage." % damage_to_player
	if winner == "player":
		var damage_to_rival: int = base_damage + player_alive
		rival_health = maxi(0, rival_health - damage_to_rival)
		return "Rival took %d damage." % damage_to_rival
	return "No player damage."


func _stage_number() -> int:
	return maxi(1, int((round_number - 1) / 4) + 1)


func _stage_base_damage(stage: int) -> int:
	match stage:
		1:
			return 1
		2:
			return 3
		3:
			return 6
		4:
			return 7
		_:
			return 8 + (stage - 5)


func _join_strings(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output
