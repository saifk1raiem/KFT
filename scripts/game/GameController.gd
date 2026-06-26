extends VBoxContainer
class_name GameController

@onready var hud: HUD = $HUD
@onready var board: BattleBoard = $BattleBoard
@onready var bench_panel: BenchPanel = $BenchPanel
@onready var shop_panel: ShopPanel = $ShopPanel

var economy := EconomySystem.new()
var shop := ShopSystem.new()
var roster := ArmyRoster.new()
var enemy_units: Array[RuntimeUnit] = []
var phase := IronEnums.GamePhase.PREP
var round_number := 1
var selected_bench_index := -1
var won_last_round := false

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

	_seed_opening_units()
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
	shop.remove_unit(unit_id)
	GameEvents.unit_bought.emit(unit)
	_set_status("Bought %s." % definition.display_name)
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

	var result: Dictionary = CombatResolver.simulate(deployed, enemy_units)
	var result_log: Array = result["log"] as Array
	for line_value: Variant in result_log:
		GameEvents.combat_log.emit(str(line_value))

	var winner: String = str(result["winner"])
	var exchanges: int = int(result["exchanges"])
	var player_alive: int = int(result["player_alive"])
	var enemy_alive: int = int(result["enemy_alive"])
	won_last_round = winner == "player"
	phase = IronEnums.GamePhase.RESULTS
	GameEvents.phase_changed.emit(phase)

	if won_last_round:
		economy.gain(2)
		_set_status("Victory after %d exchanges. Survived: %d vs %d. +2 gold." % [exchanges, player_alive, enemy_alive])
	elif winner == "enemy":
		_set_status("Defeat after %d exchanges. Survived: %d vs %d." % [exchanges, player_alive, enemy_alive])
	else:
		_set_status("Draw after %d exchanges." % exchanges)

	board.sync_units(roster.board, enemy_units)
	_refresh_all()


func _end_round() -> void:
	if phase == IronEnums.GamePhase.COMBAT:
		return

	var income := economy.award_round_income(round_number, won_last_round)
	round_number += 1
	phase = IronEnums.GamePhase.PREP
	enemy_units.clear()
	selected_bench_index = -1
	bench_panel.clear_selection()
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
	_roll_shop(false)
	_set_status("Shop refreshed.")
	_refresh_all()


func _buy_xp_pressed() -> void:
	if economy.buy_xp():
		_set_status("Bought XP.")
	else:
		_set_status("Cannot buy XP right now.")
	_refresh_all()


func _roll_shop(spend_gold: bool) -> void:
	if spend_gold and not economy.spend(EconomySystem.SHOP_REFRESH_COST):
		return
	shop.roll(economy.level)


func _on_roster_changed() -> void:
	_refresh_all()


func _refresh_all() -> void:
	hud.update_state(economy.gold, economy.level, economy.xp, round_number, phase)
	shop_panel.set_shop(shop.current_shop)
	bench_panel.set_units(roster.bench)
	board.sync_units(roster.board, enemy_units)


func _set_status(message: String) -> void:
	hud.set_status(message)
	GameEvents.status_message.emit(message)
