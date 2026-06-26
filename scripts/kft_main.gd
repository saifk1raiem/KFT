extends Control

const BOARD_SLOTS := 15
const BENCH_SLOTS := 8
const MAX_PLAYER_HP := 30
const HUMAN_ID := 0

const UNITS := {
	"recruit": {
		"name": "Barehand Recruit",
		"short": "Recruit",
		"cost": 1,
		"tier": "Militia",
		"weapon": "Bare hands",
		"hp": 30,
		"attack": 4,
		"armor": 0,
		"speed": 1.05,
		"traits": ["infantry", "militia"],
		"color": "#8a5b33",
		"copy": "Cheap body. Wins when upgraded or protected."
	},
	"dagger": {
		"name": "Knife Soldier",
		"short": "Knife",
		"cost": 1,
		"tier": "Skirmisher",
		"weapon": "Knife",
		"hp": 24,
		"attack": 5,
		"armor": 0,
		"speed": 1.28,
		"traits": ["duelist", "flanker"],
		"color": "#5d6b55",
		"copy": "Fast cuts. Executes wounded enemies."
	},
	"swordsman": {
		"name": "Sword Soldier",
		"short": "Sword",
		"cost": 2,
		"tier": "Infantry",
		"weapon": "Sword",
		"hp": 38,
		"attack": 7,
		"armor": 2,
		"speed": 1.0,
		"traits": ["infantry"],
		"color": "#76523b",
		"copy": "Balanced frontline with clean damage."
	},
	"katana": {
		"name": "Katana Duelist",
		"short": "Katana",
		"cost": 3,
		"tier": "Duelist",
		"weapon": "Katana",
		"hp": 34,
		"attack": 10,
		"armor": 1,
		"speed": 1.45,
		"traits": ["duelist"],
		"color": "#6c4048",
		"copy": "Elite striker. Crits when the duel opens."
	},
	"shield": {
		"name": "Shield Guard",
		"short": "Shield",
		"cost": 3,
		"tier": "Tank",
		"weapon": "Shield",
		"hp": 56,
		"attack": 5,
		"armor": 6,
		"speed": 0.82,
		"traits": ["infantry", "shield"],
		"color": "#526674",
		"copy": "Heavy guard. Makes a line hard to break."
	},
	"pike": {
		"name": "Pikeman",
		"short": "Pike",
		"cost": 4,
		"tier": "Anti-cavalry",
		"weapon": "Pike",
		"hp": 42,
		"attack": 11,
		"armor": 2,
		"speed": 0.9,
		"traits": ["infantry", "spear"],
		"color": "#596f45",
		"copy": "Long reach. Punishes cavalry charges."
	},
	"lancer": {
		"name": "Lancer Horseman",
		"short": "Lancer",
		"cost": 5,
		"tier": "Cavalry",
		"weapon": "Lance",
		"hp": 62,
		"attack": 15,
		"armor": 4,
		"speed": 1.22,
		"traits": ["cavalry"],
		"color": "#74432f",
		"copy": "Legendary 5-cost. The opening charge is brutal."
	}
}

const EQUIPMENT := {
	"iron_sword": {
		"name": "Iron Sword",
		"cost": 1,
		"stats": {"attack": 3},
		"copy": "+3 attack to the selected soldier."
	},
	"round_shield": {
		"name": "Round Shield",
		"cost": 1,
		"stats": {"hp": 8, "armor": 2},
		"copy": "+8 health and +2 armor."
	},
	"leather_armor": {
		"name": "Leather Armor",
		"cost": 2,
		"stats": {"hp": 18, "armor": 1},
		"copy": "A clean survival spike for any frontline."
	},
	"warhorse": {
		"name": "Warhorse",
		"cost": 3,
		"stats": {"hp": 12, "attack": 2, "speed": 0.18},
		"add_traits": ["cavalry"],
		"copy": "Adds cavalry trait and a smaller charge."
	}
}

const TACTICS := {
	"shield_wall": {
		"name": "Shield Wall",
		"cost": 2,
		"copy": "Shield units gain armor. Infantry nearby holds longer."
	},
	"spear_line": {
		"name": "Spear Line",
		"cost": 2,
		"copy": "Spears hit cavalry even harder."
	},
	"cavalry_charge": {
		"name": "Cavalry Charge",
		"cost": 3,
		"copy": "Cavalry opening attacks deal more damage."
	},
	"duelist_circle": {
		"name": "Duelist Circle",
		"cost": 2,
		"copy": "Duelists gain critical strike chance."
	},
	"royal_banner": {
		"name": "Royal Banner",
		"cost": 3,
		"copy": "Every deployed soldier gains +1 attack."
	}
}

const TRAIT_RULES := [
	{"key": "infantry", "name": "Infantry", "threshold": 3},
	{"key": "duelist", "name": "Duelists", "threshold": 2},
	{"key": "shield", "name": "Shield Wall", "threshold": 2},
	{"key": "spear", "name": "Spears", "threshold": 2},
	{"key": "cavalry", "name": "Cavalry", "threshold": 1}
]

const AI_NAMES := [
	"North Gate",
	"Ash Banner",
	"Red Abbey",
	"Stone Vale",
	"Black Road",
	"High Orchard",
	"Silver Ford"
]

var rng := RandomNumberGenerator.new()
var players := []
var shop := []
var log_lines: Array[String] = []
var round_num := 1
var phase := "draft"
var pick_used := false
var selected_zone := ""
var selected_index := -1
var current_opponent_id := -1
var uid_counter := 1
var card_counter := 1
var game_over := false
var last_result := "Unblooded"

var round_value: Label
var phase_value: Label
var coin_value: Label
var army_value: Label
var alive_value: Label
var opponent_value: Label
var result_value: Label
var standings_list: VBoxContainer
var enemy_grid: GridContainer
var player_grid: GridContainer
var bench_row: GridContainer
var shop_row: HBoxContainer
var selection_panel: PanelContainer
var selection_text: RichTextLabel
var synergy_text: RichTextLabel
var combat_log: RichTextLabel
var battle_button: Button
var sell_button: Button
var end_banner: PanelContainer
var end_title: Label
var end_body: Label


func _ready() -> void:
	rng.randomize()
	build_ui()
	new_game()


func build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color.html("#16110d")
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	build_topbar(root)
	build_play_area(root)
	build_shop(root)
	build_end_banner()


func build_topbar(root: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 78)
	panel.add_theme_stylebox_override("panel", make_style("#241810", "#4b3828", 8))
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size = Vector2(270, 0)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)

	var title := Label.new()
	title.text = "KFT"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.html("#f8ecd2"))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Kingdom Fight Tactics"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color.html("#b9a88d"))
	title_box.add_child(subtitle)

	var stats := GridContainer.new()
	stats.columns = 5
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stats)

	round_value = add_stat(stats, "Round")
	phase_value = add_stat(stats, "Phase")
	coin_value = add_stat(stats, "Coins")
	army_value = add_stat(stats, "Army")
	alive_value = add_stat(stats, "Alive")

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	row.add_child(actions)

	var new_button := Button.new()
	new_button.text = "New War"
	stylize_button(new_button, "#3a2a20", "#6e4128")
	new_button.pressed.connect(new_game)
	actions.add_child(new_button)

	battle_button = Button.new()
	battle_button.text = "Begin Battle"
	stylize_button(battle_button, "#d6a744", "#f0cc73", true)
	battle_button.pressed.connect(_on_battle_pressed)
	actions.add_child(battle_button)


func build_play_area(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	var standings_panel := PanelContainer.new()
	standings_panel.custom_minimum_size = Vector2(220, 0)
	standings_panel.add_theme_stylebox_override("panel", make_style("#241810", "#4b3828", 8))
	row.add_child(standings_panel)

	var standings_box := VBoxContainer.new()
	standings_box.add_theme_constant_override("separation", 8)
	standings_panel.add_child(standings_box)
	standings_box.add_child(make_section_label("War Table"))

	var standings_scroll := ScrollContainer.new()
	standings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	standings_box.add_child(standings_scroll)

	standings_list = VBoxContainer.new()
	standings_list.add_theme_constant_override("separation", 8)
	standings_scroll.add_child(standings_list)

	var stage_panel := PanelContainer.new()
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.add_theme_stylebox_override("panel", make_style("#302116", "#5a412e", 8))
	row.add_child(stage_panel)

	var stage := VBoxContainer.new()
	stage.add_theme_constant_override("separation", 10)
	stage_panel.add_child(stage)

	var match_row := HBoxContainer.new()
	match_row.add_theme_constant_override("separation", 8)
	stage.add_child(match_row)
	opponent_value = add_match_stat(match_row, "Opponent")
	result_value = add_match_stat(match_row, "Last Result")

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", make_style("#3b2a1c", "#6e5135", 8))
	stage.add_child(board_panel)

	var board_stack := VBoxContainer.new()
	board_stack.add_theme_constant_override("separation", 8)
	board_panel.add_child(board_stack)

	var enemy_label := make_small_label("Enemy line")
	board_stack.add_child(enemy_label)

	enemy_grid = GridContainer.new()
	enemy_grid.columns = 5
	enemy_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_stack.add_child(enemy_grid)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color.html("#9b825c")
	board_stack.add_child(divider)

	player_grid = GridContainer.new()
	player_grid.columns = 5
	player_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_stack.add_child(player_grid)

	var player_label := make_small_label("Your line")
	board_stack.add_child(player_label)

	var bench_panel := PanelContainer.new()
	bench_panel.custom_minimum_size = Vector2(0, 96)
	bench_panel.add_theme_stylebox_override("panel", make_style("#221811", "#4b3828", 8))
	stage.add_child(bench_panel)

	var bench_box := VBoxContainer.new()
	bench_box.add_theme_constant_override("separation", 8)
	bench_panel.add_child(bench_box)

	var bench_head := HBoxContainer.new()
	bench_box.add_child(bench_head)
	bench_head.add_child(make_section_label("Bench"))

	sell_button = Button.new()
	sell_button.text = "Sell Selected"
	sell_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	stylize_button(sell_button, "#8e2f28", "#d94b3f")
	sell_button.pressed.connect(_on_sell_pressed)
	bench_head.add_child(sell_button)

	bench_row = GridContainer.new()
	bench_row.columns = BENCH_SLOTS
	bench_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_box.add_child(bench_row)

	var command_panel := PanelContainer.new()
	command_panel.custom_minimum_size = Vector2(300, 0)
	command_panel.add_theme_stylebox_override("panel", make_style("#241810", "#4b3828", 8))
	row.add_child(command_panel)

	var command := VBoxContainer.new()
	command.add_theme_constant_override("separation", 10)
	command_panel.add_child(command)
	command.add_child(make_section_label("Command"))

	selection_panel = PanelContainer.new()
	selection_panel.custom_minimum_size = Vector2(0, 142)
	selection_panel.add_theme_stylebox_override("panel", make_style("#17100c", "#4b3828", 7))
	command.add_child(selection_panel)

	selection_text = RichTextLabel.new()
	selection_text.fit_content = true
	selection_text.bbcode_enabled = true
	selection_text.scroll_active = false
	selection_panel.add_child(selection_text)

	var synergy_panel := PanelContainer.new()
	synergy_panel.custom_minimum_size = Vector2(0, 120)
	synergy_panel.add_theme_stylebox_override("panel", make_style("#17100c", "#4b3828", 7))
	command.add_child(synergy_panel)

	synergy_text = RichTextLabel.new()
	synergy_text.fit_content = true
	synergy_text.bbcode_enabled = true
	synergy_text.scroll_active = false
	synergy_panel.add_child(synergy_text)

	var log_panel := PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", make_style("#17100c", "#4b3828", 7))
	command.add_child(log_panel)

	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(combat_log)


func build_shop(root: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 218)
	panel.add_theme_stylebox_override("panel", make_style("#2b1d14", "#5a412e", 8))
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	head.add_child(make_section_label("Draft Cards"))

	var hint := Label.new()
	hint.text = "Choose one card each round"
	hint.add_theme_color_override("font_color", Color.html("#b9a88d"))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(hint)

	shop_row = HBoxContainer.new()
	shop_row.add_theme_constant_override("separation", 10)
	shop_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(shop_row)


func build_end_banner() -> void:
	end_banner = PanelContainer.new()
	end_banner.visible = false
	end_banner.custom_minimum_size = Vector2(500, 230)
	end_banner.set_anchors_preset(Control.PRESET_CENTER)
	end_banner.position = Vector2(550, 310)
	end_banner.add_theme_stylebox_override("panel", make_style("#24170f", "#d6a744", 8))
	add_child(end_banner)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	end_banner.add_child(box)

	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 42)
	end_title.add_theme_color_override("font_color", Color.html("#f0cc73"))
	box.add_child(end_title)

	end_body = Label.new()
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_body.add_theme_color_override("font_color", Color.html("#f8ecd2"))
	box.add_child(end_body)

	var restart := Button.new()
	restart.text = "Start Again"
	stylize_button(restart, "#d6a744", "#f0cc73", true)
	restart.pressed.connect(new_game)
	box.add_child(restart)


func new_game() -> void:
	players.clear()
	shop.clear()
	log_lines.clear()
	round_num = 1
	phase = "draft"
	pick_used = false
	selected_zone = ""
	selected_index = -1
	current_opponent_id = -1
	uid_counter = 1
	card_counter = 1
	game_over = false
	last_result = "Unblooded"
	end_banner.visible = false

	players.append(create_player(HUMAN_ID, "You", true))
	for i in range(AI_NAMES.size()):
		players.append(create_player(i + 1, AI_NAMES[i], false))

	add_log("The KFT war table is set.")
	prepare_draft(true)


func create_player(id: int, player_name: String, is_human: bool) -> Dictionary:
	return {
		"id": id,
		"name": player_name,
		"is_human": is_human,
		"hp": MAX_PLAYER_HP,
		"coins": 1,
		"board": empty_slots(BOARD_SLOTS),
		"bench": empty_slots(BENCH_SLOTS),
		"tactics": [],
		"alive": true,
		"streak": 0,
		"last_result": "-"
	}


func empty_slots(count: int) -> Array:
	var slots := []
	for _i in range(count):
		slots.append(null)
	return slots


func prepare_draft(initial: bool = false) -> void:
	phase = "draft"
	pick_used = false
	selected_zone = ""
	selected_index = -1

	if not initial:
		for player in alive_players():
			player["coins"] += 1
		add_log("Dawn income: every surviving army gains 1 coin.")

	for player in players:
		if player["id"] != HUMAN_ID and player["alive"]:
			run_ai_draft(player)

	current_opponent_id = pick_opponent_id()
	shop = generate_shop(round_num)
	render()


func alive_players() -> Array:
	var alive := []
	for player in players:
		if player["alive"]:
			alive.append(player)
	return alive


func human() -> Dictionary:
	return players[0]


func opponent() -> Dictionary:
	for player in players:
		if player["id"] == current_opponent_id:
			return player
	return {}


func board_cap() -> int:
	return mini(7, 2 + floori(float(round_num - 1) / 2.0))


func make_unit(key: String) -> Dictionary:
	var unit := {
		"uid": uid_counter,
		"key": key,
		"star": 1,
		"items": []
	}
	uid_counter += 1
	return unit


func generate_shop(current_round: int) -> Array:
	var cards := []
	var seen := {}

	while cards.size() < 5:
		var card := random_card(current_round)
		var sig := "%s:%s" % [card["type"], card["key"]]
		if seen.has(sig) and rng.randf() > 0.35:
			continue
		seen[sig] = true
		cards.append(card)

	var has_opening_unit := false
	for card in cards:
		if card["type"] == "unit" and card["cost"] == 1:
			has_opening_unit = true
			break
	if current_round == 1 and not has_opening_unit:
		cards[0] = make_unit_card("recruit" if rng.randf() > 0.5 else "dagger")

	return cards


func random_card(current_round: int) -> Dictionary:
	var roll := rng.randf()
	if roll < 0.64:
		return make_unit_card(weighted_unit_key(current_round))
	if roll < 0.86:
		return make_equipment_card(weighted_library_key(EQUIPMENT, current_round))
	return make_tactic_card(weighted_library_key(TACTICS, current_round))


func max_cost_for_round(current_round: int) -> int:
	return mini(5, maxi(1, 1 + floori(float(current_round) / 2.0)))


func weighted_unit_key(current_round: int) -> String:
	var max_cost := max_cost_for_round(current_round)
	var deck := []

	for key in UNITS.keys():
		var unit: Dictionary = UNITS[key]
		var unlocked := int(unit["cost"]) <= max_cost or rng.randf() < 0.05 + float(current_round) * 0.006
		if not unlocked:
			continue
		var copies := maxi(1, roundi(8.0 - float(unit["cost"]) * 1.25 + (2.0 if int(unit["cost"]) <= max_cost else 0.0)))
		for _i in range(copies):
			deck.append(key)

	if deck.is_empty():
		return "recruit"
	return deck[rng.randi_range(0, deck.size() - 1)]


func weighted_library_key(library: Dictionary, current_round: int) -> String:
	var max_cost := max_cost_for_round(current_round)
	var deck := []
	for key in library.keys():
		var entry: Dictionary = library[key]
		if int(entry["cost"]) <= max_cost or rng.randf() < 0.08:
			var copies := maxi(1, 5 - int(entry["cost"]))
			for _i in range(copies):
				deck.append(key)
	if deck.is_empty():
		return library.keys()[0]
	return deck[rng.randi_range(0, deck.size() - 1)]


func make_unit_card(key: String) -> Dictionary:
	var unit: Dictionary = UNITS[key]
	var card := {
		"id": card_counter,
		"type": "unit",
		"key": key,
		"name": unit["name"],
		"cost": unit["cost"],
		"label": unit["tier"],
		"copy": unit["copy"],
		"picked": false
	}
	card_counter += 1
	return card


func make_equipment_card(key: String) -> Dictionary:
	var item: Dictionary = EQUIPMENT[key]
	var card := {
		"id": card_counter,
		"type": "equipment",
		"key": key,
		"name": item["name"],
		"cost": item["cost"],
		"label": "Equipment",
		"copy": item["copy"],
		"picked": false
	}
	card_counter += 1
	return card


func make_tactic_card(key: String) -> Dictionary:
	var tactic: Dictionary = TACTICS[key]
	var card := {
		"id": card_counter,
		"type": "tactic",
		"key": key,
		"name": tactic["name"],
		"cost": tactic["cost"],
		"label": "Formation",
		"copy": tactic["copy"],
		"picked": false
	}
	card_counter += 1
	return card


func run_ai_draft(player: Dictionary) -> void:
	var cards := generate_shop(round_num)
	var scored := []

	for card in cards:
		if int(card["cost"]) <= int(player["coins"]):
			scored.append({"card": card, "score": score_card_for_ai(player, card)})

	if scored.is_empty():
		return

	scored.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	buy_card(player, scored[0]["card"], true)


func score_card_for_ai(player: Dictionary, card: Dictionary) -> float:
	if card["type"] == "unit":
		var unit: Dictionary = UNITS[card["key"]]
		var copies := 0
		for entry in all_units(player):
			if entry["unit"]["key"] == card["key"]:
				copies += 1
		var traits := count_traits(player)
		var trait_need := 0
		for trait in unit["traits"]:
			trait_need += int(traits.get(trait, 0))
		return float(unit["cost"]) * 12.0 + float(copies) * 10.0 + float(trait_need) * 4.0 + rng.randf() * 8.0

	if card["type"] == "equipment":
		return float(all_units(player).size()) * 8.0 + float(card["cost"]) * 5.0 + rng.randf() * 8.0

	if player["tactics"].has(card["key"]):
		return -5.0

	return 18.0 + float(card["cost"]) * 8.0 + rng.randf() * 8.0


func buy_card(player: Dictionary, card: Dictionary, silent: bool = false) -> bool:
	if not player["alive"] or int(player["coins"]) < int(card["cost"]):
		return false
	if player["id"] == HUMAN_ID and pick_used:
		return false
	if card["type"] == "tactic" and player["tactics"].has(card["key"]):
		if not silent:
			add_log("%s is already active." % TACTICS[card["key"]]["name"])
		return false

	player["coins"] -= int(card["cost"])

	if card["type"] == "unit":
		var unit := make_unit(card["key"])
		if not add_unit_to_army(player, unit):
			player["coins"] += int(card["cost"])
			if not silent:
				add_log("No room for another soldier.")
			return false
		try_upgrade(player, unit["key"])
		if not silent:
			add_log("%s drafted %s." % [player["name"], UNITS[unit["key"]]["name"]])

	if card["type"] == "equipment":
		var target := choose_equipment_target(player)
		if target.is_empty():
			player["coins"] += int(card["cost"])
			if not silent:
				add_log("No soldier can carry that equipment.")
			return false
		target["unit"]["items"].append(card["key"])
		if not silent:
			add_log("%s equipped on %s." % [EQUIPMENT[card["key"]]["name"], UNITS[target["unit"]["key"]]["short"]])

	if card["type"] == "tactic":
		player["tactics"].append(card["key"])
		if not silent:
			add_log("%s committed to %s." % [player["name"], TACTICS[card["key"]]["name"]])

	if player["id"] == HUMAN_ID:
		pick_used = true
		for shop_card in shop:
			shop_card["picked"] = shop_card["id"] == card["id"]
		selected_zone = ""
		selected_index = -1
		render()

	return true


func add_unit_to_army(player: Dictionary, unit: Dictionary) -> bool:
	if count_board_units(player) < board_cap():
		var preferred := [12, 11, 13, 7, 6, 8, 10, 14, 2, 1, 3, 5, 9, 0, 4]
		for slot in preferred:
			if player["board"][slot] == null:
				player["board"][slot] = unit
				return true

	for i in range(BENCH_SLOTS):
		if player["bench"][i] == null:
			player["bench"][i] = unit
			return true

	return false


func try_upgrade(player: Dictionary, key: String) -> void:
	for star in range(1, 3):
		var matches := matching_units(player, key, star)
		while matches.size() >= 3:
			var keeper: Dictionary = matches[0]
			var first_consumed: Dictionary = matches[1]
			var second_consumed: Dictionary = matches[2]
			var combined_items := []
			combined_items.append_array(keeper["unit"]["items"])
			combined_items.append_array(first_consumed["unit"]["items"])
			combined_items.append_array(second_consumed["unit"]["items"])
			keeper["unit"]["star"] += 1
			keeper["unit"]["items"] = combined_items.slice(0, 2)
			remove_unit_at(player, first_consumed["zone"], first_consumed["index"])
			remove_unit_at(player, second_consumed["zone"], second_consumed["index"])
			add_log("%s reached %d stars." % [UNITS[key]["name"], keeper["unit"]["star"]])
			matches = matching_units(player, key, star)


func matching_units(player: Dictionary, key: String, star: int) -> Array:
	var matches := []
	for entry in all_units(player):
		if entry["unit"]["key"] == key and int(entry["unit"]["star"]) == star:
			matches.append(entry)
	return matches


func remove_unit_at(player: Dictionary, zone: String, index: int) -> void:
	if zone == "board":
		player["board"][index] = null
	else:
		player["bench"][index] = null


func choose_equipment_target(player: Dictionary) -> Dictionary:
	var selected := get_selected_unit(player)
	if not selected.is_empty() and selected["unit"]["items"].size() < 2:
		return selected

	var candidates := []
	for entry in all_units(player):
		if entry["unit"]["items"].size() < 2:
			candidates.append(entry)

	if candidates.is_empty():
		return {}

	candidates.sort_custom(func(a, b): return unit_power(a["unit"], player) > unit_power(b["unit"], player))
	return candidates[0]


func get_selected_unit(player: Dictionary) -> Dictionary:
	if selected_zone == "" or player["id"] != HUMAN_ID:
		return {}
	var collection: Array = player["board"] if selected_zone == "board" else player["bench"]
	if selected_index < 0 or selected_index >= collection.size():
		return {}
	var unit = collection[selected_index]
	if unit == null:
		return {}
	return {"zone": selected_zone, "index": selected_index, "unit": unit}


func all_units(player: Dictionary) -> Array:
	var units := []
	for i in range(BOARD_SLOTS):
		if player["board"][i] != null:
			units.append({"zone": "board", "index": i, "unit": player["board"][i]})
	for i in range(BENCH_SLOTS):
		if player["bench"][i] != null:
			units.append({"zone": "bench", "index": i, "unit": player["bench"][i]})
	return units


func board_units(player: Dictionary) -> Array:
	var units := []
	for i in range(BOARD_SLOTS):
		if player["board"][i] != null:
			units.append({"zone": "board", "index": i, "unit": player["board"][i]})
	return units


func count_board_units(player: Dictionary) -> int:
	var count := 0
	for unit in player["board"]:
		if unit != null:
			count += 1
	return count


func count_traits(player: Dictionary) -> Dictionary:
	var counts := {}
	for entry in board_units(player):
		for trait in get_unit_traits(entry["unit"]):
			counts[trait] = int(counts.get(trait, 0)) + 1
	return counts


func get_unit_traits(unit: Dictionary) -> Array:
	var traits := []
	for trait in UNITS[unit["key"]]["traits"]:
		if not traits.has(trait):
			traits.append(trait)
	for item_key in unit["items"]:
		for trait in EQUIPMENT[item_key].get("add_traits", []):
			if not traits.has(trait):
				traits.append(trait)
	return traits


func team_context(player: Dictionary) -> Dictionary:
	var traits := count_traits(player)
	var tactics: Array = player["tactics"]
	return {
		"traits": traits,
		"infantry_armor": 1 if int(traits.get("infantry", 0)) >= 3 else 0,
		"duelist_crit": (0.12 if int(traits.get("duelist", 0)) >= 2 else 0.0) + (0.15 if tactics.has("duelist_circle") else 0.0),
		"shield_armor": (2 if int(traits.get("shield", 0)) >= 2 else 0) + (2 if tactics.has("shield_wall") else 0),
		"spear_bonus": (0.45 if int(traits.get("spear", 0)) >= 2 else 0.0) + (0.55 if tactics.has("spear_line") else 0.0),
		"cavalry_charge": 0.55 if tactics.has("cavalry_charge") else 0.0,
		"banner_attack": 1 if tactics.has("royal_banner") else 0
	}


func get_unit_stats(unit: Dictionary, player: Dictionary, context: Dictionary = {}) -> Dictionary:
	var local_context := context
	if local_context.is_empty():
		local_context = team_context(player)

	var base: Dictionary = UNITS[unit["key"]]
	var star_scale := 1.0 + float(int(unit["star"]) - 1) * 0.58
	var item_hp := 0
	var item_attack := 0
	var item_armor := 0
	var item_speed := 0.0

	for item_key in unit["items"]:
		var stats: Dictionary = EQUIPMENT[item_key].get("stats", {})
		item_hp += int(stats.get("hp", 0))
		item_attack += int(stats.get("attack", 0))
		item_armor += int(stats.get("armor", 0))
		item_speed += float(stats.get("speed", 0.0))

	var traits := get_unit_traits(unit)
	var shield_bonus := int(local_context["shield_armor"]) if traits.has("shield") else 0
	var infantry_bonus := int(local_context["infantry_armor"]) if traits.has("infantry") else 0

	return {
		"max_hp": roundi(float(base["hp"]) * star_scale + float(item_hp)),
		"attack": roundi(float(base["attack"]) * star_scale + float(item_attack) + float(local_context["banner_attack"])),
		"armor": maxi(0, int(base["armor"]) + item_armor + shield_bonus + infantry_bonus),
		"speed": float(base["speed"]) + item_speed,
		"crit": (0.08 + float(local_context["duelist_crit"])) if traits.has("duelist") else 0.03,
		"traits": traits
	}


func unit_power(unit: Dictionary, player: Dictionary) -> float:
	var stats := get_unit_stats(unit, player)
	return float(stats["max_hp"]) * 0.42 + float(stats["attack"]) * 6.0 + float(stats["armor"]) * 4.0 + float(stats["speed"]) * 12.0 + float(unit["star"]) * 18.0


func pick_opponent_id() -> int:
	var enemies := []
	for player in players:
		if player["id"] != HUMAN_ID and player["alive"]:
			enemies.append(player)
	if enemies.is_empty():
		return -1
	enemies.shuffle()
	return enemies[0]["id"]


func render() -> void:
	var player := human()
	var enemy := opponent()
	var alive_count := alive_players().size()

	round_value.text = str(round_num)
	phase_value.text = label_phase(phase)
	coin_value.text = str(player["coins"])
	army_value.text = "%d/%d" % [count_board_units(player), board_cap()]
	alive_value.text = str(alive_count)
	opponent_value.text = enemy.get("name", "None")
	result_value.text = last_result
	battle_button.disabled = phase != "draft" or game_over
	sell_button.disabled = get_selected_unit(player).is_empty() or phase != "draft"

	render_standings()
	render_board(player, enemy)
	render_bench(player)
	render_shop(player)
	render_selection(player)
	render_synergies(player)
	render_log()


func label_phase(value: String) -> String:
	if value == "draft":
		return "Draft"
	if value == "combat":
		return "Combat"
	if value == "results":
		return "Results"
	if value == "ended":
		return "Ended"
	return value


func render_standings() -> void:
	clear_children(standings_list)
	var sorted_players := players.duplicate()
	sorted_players.sort_custom(func(a, b): return int(a["hp"]) > int(b["hp"]))

	for player in sorted_players:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", make_style("#17100c" if player["alive"] else "#191817", "#d6a744" if player["id"] == HUMAN_ID else "#4b3828", 7))
		standings_list.add_child(row)

		var box := HBoxContainer.new()
		row.add_child(box)

		var text := Label.new()
		text.text = "%s\n%d HP | %d coins | %d units" % [player["name"], player["hp"], player["coins"], count_board_units(player)]
		text.add_theme_color_override("font_color", Color.html("#f8ecd2") if player["alive"] else Color.html("#7e715f"))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(text)


func render_board(player: Dictionary, enemy: Dictionary) -> void:
	clear_children(enemy_grid)
	clear_children(player_grid)

	for i in range(BOARD_SLOTS):
		var unit = null
		if not enemy.is_empty():
			unit = enemy["board"][i]
		enemy_grid.add_child(make_board_button(unit, enemy, i, false))

	for i in range(BOARD_SLOTS):
		var unit = player["board"][i]
		var button := make_board_button(unit, player, i, true)
		button.pressed.connect(_on_board_cell_pressed.bind(i))
		player_grid.add_child(button)


func make_board_button(unit, owner: Dictionary, slot: int, interactive: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(96, 66)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not interactive or phase != "draft"
	button.text = unit_label(unit, owner) if unit != null else ""
	button.tooltip_text = unit_tooltip(unit, owner) if unit != null else "Empty board slot"
	var selected := interactive and selected_zone == "board" and selected_index == slot
	stylize_button(button, "#4a3423" if not selected else "#6b4a23", "#f0cc73" if selected else "#6e5135")
	return button


func render_bench(player: Dictionary) -> void:
	clear_children(bench_row)
	for i in range(BENCH_SLOTS):
		var unit = player["bench"][i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(86, 62)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = phase != "draft"
		button.text = unit_label(unit, player) if unit != null else "-"
		button.tooltip_text = unit_tooltip(unit, player) if unit != null else "Empty bench slot"
		var selected := selected_zone == "bench" and selected_index == i
		stylize_button(button, "#2a1d14" if not selected else "#6b4a23", "#f0cc73" if selected else "#4b3828")
		button.pressed.connect(_on_bench_pressed.bind(i))
		bench_row.add_child(button)


func render_shop(player: Dictionary) -> void:
	clear_children(shop_row)
	for i in range(shop.size()):
		var card: Dictionary = shop[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 160)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.text = "%s\n%s\nCost %d\n\n%s" % [card["name"], card["label"], card["cost"], card["copy"]]
		button.tooltip_text = button.text
		button.disabled = phase != "draft" or pick_used or int(player["coins"]) < int(card["cost"])
		stylize_button(button, card_color(card), "#f0cc73" if card["picked"] else "#6e5135")
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		shop_row.add_child(button)


func render_selection(player: Dictionary) -> void:
	var selected := get_selected_unit(player)
	if selected.is_empty():
		selection_text.text = "[center][color=#b9a88d]No soldier selected[/color][/center]"
		return

	var unit: Dictionary = selected["unit"]
	var base: Dictionary = UNITS[unit["key"]]
	var stats := get_unit_stats(unit, player)
	var item_names := []
	for item_key in unit["items"]:
		item_names.append(EQUIPMENT[item_key]["name"])
	var item_text := "No equipment" if item_names.is_empty() else join_strings(item_names, ", ")

	selection_text.text = "[b]%s[/b]\n%s | %s\n\nHP %d   ATK %d   ARM %d   SPD %.2f" % [
		base["name"],
		base["weapon"],
		item_text,
		stats["max_hp"],
		stats["attack"],
		stats["armor"],
		stats["speed"]
	]


func render_synergies(player: Dictionary) -> void:
	var counts := count_traits(player)
	var lines := ["[b]Traits[/b]"]
	for rule in TRAIT_RULES:
		var count := int(counts.get(rule["key"], 0))
		var active := count >= int(rule["threshold"])
		lines.append("%s%s %d/%d%s" % [
			"[color=#f0cc73]" if active else "[color=#b9a88d]",
			rule["name"],
			count,
			rule["threshold"],
			"[/color]"
		])

	if not player["tactics"].is_empty():
		lines.append("\n[b]Formations[/b]")
		for tactic_key in player["tactics"]:
			lines.append("[color=#f0cc73]%s[/color]" % TACTICS[tactic_key]["name"])

	synergy_text.text = join_strings(lines, "\n")


func render_log() -> void:
	var lines := []
	var start := maxi(0, log_lines.size() - 9)
	for i in range(log_lines.size() - 1, start - 1, -1):
		lines.append(log_lines[i])
	combat_log.text = join_strings(lines, "\n\n")


func _on_shop_card_pressed(index: int) -> void:
	if index < 0 or index >= shop.size():
		return
	buy_card(human(), shop[index], false)


func _on_board_cell_pressed(slot: int) -> void:
	if phase != "draft":
		return

	var player := human()
	var clicked = player["board"][slot]
	var selected := get_selected_unit(player)

	if selected.is_empty():
		if clicked != null:
			selected_zone = "board"
			selected_index = slot
			render()
		return

	if selected["zone"] == "bench":
		if clicked == null and count_board_units(player) >= board_cap():
			add_log("Army cap reached for this round.")
			render()
			return
		player["bench"][selected["index"]] = clicked
		player["board"][slot] = selected["unit"]
		selected_zone = "board"
		selected_index = slot
		render()
		return

	if selected["zone"] == "board":
		player["board"][selected["index"]] = clicked
		player["board"][slot] = selected["unit"]
		selected_zone = "board"
		selected_index = slot
		render()


func _on_bench_pressed(index: int) -> void:
	if phase != "draft":
		return

	var player := human()
	var clicked = player["bench"][index]
	var selected := get_selected_unit(player)

	if selected.is_empty():
		if clicked != null:
			selected_zone = "bench"
			selected_index = index
			render()
		return

	if selected["zone"] == "board":
		player["board"][selected["index"]] = clicked
		player["bench"][index] = selected["unit"]
		selected_zone = "bench"
		selected_index = index
		render()
		return

	if clicked != null:
		selected_zone = "bench"
		selected_index = index
		render()
		return

	player["bench"][selected["index"]] = null
	player["bench"][index] = selected["unit"]
	selected_zone = "bench"
	selected_index = index
	render()


func _on_sell_pressed() -> void:
	if phase != "draft":
		return

	var player := human()
	var selected := get_selected_unit(player)
	if selected.is_empty():
		return

	var unit: Dictionary = selected["unit"]
	var value := maxi(1, floori(float(UNITS[unit["key"]]["cost"]) * float(unit["star"]) * 0.75) + unit["items"].size())
	remove_unit_at(player, selected["zone"], selected["index"])
	player["coins"] += value
	selected_zone = ""
	selected_index = -1
	add_log("%s sold for %d coin%s." % [UNITS[unit["key"]]["name"], value, "" if value == 1 else "s"])
	render()


func _on_battle_pressed() -> void:
	if phase != "draft" or game_over:
		return
	await begin_combat()


func begin_combat() -> void:
	var player := human()
	var enemy := opponent()
	if enemy.is_empty():
		finish_game(true)
		return

	phase = "combat"
	selected_zone = ""
	selected_index = -1
	add_log("Battle begins against %s." % enemy["name"])
	render()
	await get_tree().create_timer(0.45).timeout

	var result := simulate_battle(player, enemy)
	apply_battle_result(player, enemy, result)
	resolve_ai_battles(enemy["id"])
	mark_eliminations()
	render()

	if check_end_state():
		return

	phase = "results"
	render()
	await get_tree().create_timer(0.85).timeout
	round_num += 1
	prepare_draft(false)


func resolve_ai_battles(excluded_id: int) -> void:
	var pool := []
	for player in players:
		if player["alive"] and player["id"] != HUMAN_ID and player["id"] != excluded_id:
			pool.append(player)
	pool.shuffle()

	var i := 0
	while i < pool.size() - 1:
		var left: Dictionary = pool[i]
		var right: Dictionary = pool[i + 1]
		var result := simulate_battle(left, right)
		apply_battle_result(left, right, result, true)
		i += 2


func simulate_battle(left_player: Dictionary, right_player: Dictionary) -> Dictionary:
	var left := build_fighters(left_player, "left")
	var right := build_fighters(right_player, "right")

	for _wave in range(24):
		if not has_living(left) or not has_living(right):
			break

		var order := living(left)
		order.append_array(living(right))
		order.shuffle()
		order.sort_custom(func(a, b): return float(a["stats"]["speed"]) > float(b["stats"]["speed"]))

		for attacker in order:
			if not attacker["alive"]:
				continue
			var enemies := right if attacker["side"] == "left" else left
			if not has_living(enemies):
				break
			var target := choose_target(attacker, enemies)
			var damage := calculate_damage(attacker, target)
			deal_damage(target, damage)

	var winner := "draw"
	if has_living(left) and not has_living(right):
		winner = "left"
	elif has_living(right) and not has_living(left):
		winner = "right"

	return {
		"winner": winner,
		"left": left,
		"right": right
	}


func build_fighters(player: Dictionary, side: String) -> Array:
	var fighters := []
	var context := team_context(player)
	for i in range(BOARD_SLOTS):
		var unit = player["board"][i]
		if unit == null:
			continue
		var stats := get_unit_stats(unit, player, context)
		fighters.append({
			"unit": unit,
			"player": player,
			"side": side,
			"slot": i,
			"stats": stats,
			"hp": stats["max_hp"],
			"max_hp": stats["max_hp"],
			"alive": true,
			"charged": false
		})
	return fighters


func has_living(fighters: Array) -> bool:
	for fighter in fighters:
		if fighter["alive"]:
			return true
	return false


func living(fighters: Array) -> Array:
	var alive := []
	for fighter in fighters:
		if fighter["alive"]:
			alive.append(fighter)
	return alive


func choose_target(attacker: Dictionary, enemies: Array) -> Dictionary:
	var living_enemies := living(enemies)
	if attacker["stats"]["traits"].has("cavalry") and not attacker["charged"]:
		living_enemies.sort_custom(func(a, b): return int(a["stats"]["armor"]) < int(b["stats"]["armor"]))
		return living_enemies[0]

	var attacker_pos := slot_position(attacker["slot"], attacker["side"])
	living_enemies.sort_custom(func(a, b): return board_distance(attacker_pos, slot_position(a["slot"], a["side"])) < board_distance(attacker_pos, slot_position(b["slot"], b["side"])))
	return living_enemies[0]


func slot_position(slot: int, side: String) -> Vector2i:
	var row := floori(float(slot) / 5.0)
	var col := slot % 5
	if side == "left":
		return Vector2i(col, 5 - row)
	return Vector2i(col, row)


func board_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func calculate_damage(attacker: Dictionary, target: Dictionary) -> int:
	var damage := float(attacker["stats"]["attack"])
	var traits: Array = attacker["stats"]["traits"]
	var target_traits: Array = target["stats"]["traits"]
	var context := team_context(attacker["player"])

	if traits.has("cavalry") and not attacker["charged"]:
		damage *= 1.65 + float(context["cavalry_charge"])
		attacker["charged"] = true

	if traits.has("spear") and target_traits.has("cavalry"):
		damage *= 1.75 + float(context["spear_bonus"])

	if traits.has("duelist") and rng.randf() < float(attacker["stats"]["crit"]):
		damage *= 1.65

	if traits.has("flanker") and float(target["hp"]) < float(target["max_hp"]) * 0.45:
		damage *= 1.35

	damage -= float(target["stats"]["armor"]) * 0.55
	return maxi(1, roundi(damage))


func deal_damage(target: Dictionary, damage: int) -> void:
	target["hp"] = maxi(0, int(target["hp"]) - damage)
	if int(target["hp"]) <= 0:
		target["alive"] = false


func apply_battle_result(left_player: Dictionary, right_player: Dictionary, result: Dictionary, silent: bool = false) -> void:
	if result["winner"] == "draw":
		left_player["hp"] -= 2
		right_player["hp"] -= 2
		left_player["last_result"] = "Draw"
		right_player["last_result"] = "Draw"
		if not silent:
			last_result = "Draw"
			add_log("Both armies broke at the same time.")
		return

	var left_won := result["winner"] == "left"
	var winner := left_player if left_won else right_player
	var loser := right_player if left_won else left_player
	var survivors: Array = result["left"] if left_won else result["right"]
	var damage := player_damage(survivors)

	loser["hp"] -= damage
	winner["coins"] += 2 + maxi(0, mini(2, int(winner["streak"])))
	loser["coins"] = maxi(0, int(loser["coins"]) - 1)
	winner["streak"] += 1
	loser["streak"] = 0
	winner["last_result"] = "Win"
	loser["last_result"] = "Loss"

	if not silent:
		last_result = "Victory" if winner["id"] == HUMAN_ID else "Defeat"
		add_log("%s wins. %s loses %d HP and 1 coin." % [winner["name"], loser["name"], damage])


func player_damage(winner_fighters: Array) -> int:
	var survivor_stars := 0
	for fighter in winner_fighters:
		if fighter["alive"]:
			survivor_stars += int(fighter["unit"]["star"])
	return mini(14, 2 + floori(float(round_num) / 2.0) + survivor_stars)


func mark_eliminations() -> void:
	for player in players:
		if int(player["hp"]) <= 0 and player["alive"]:
			player["alive"] = false
			player["hp"] = 0
			add_log("%s has fallen." % player["name"])


func check_end_state() -> bool:
	var player := human()
	if not player["alive"]:
		finish_game(false)
		return true

	var enemies_alive := false
	for entry in players:
		if entry["id"] != HUMAN_ID and entry["alive"]:
			enemies_alive = true
			break

	if not enemies_alive:
		finish_game(true)
		return true

	return false


func finish_game(victory: bool) -> void:
	game_over = true
	phase = "ended"
	end_banner.visible = true
	end_title.text = "Victory" if victory else "Defeat"
	end_body.text = "Your formation survived every rival army." if victory else "Your warband fell before the final banner."
	render()


func unit_label(unit, owner: Dictionary) -> String:
	if unit == null:
		return ""
	var data: Dictionary = UNITS[unit["key"]]
	var stats := get_unit_stats(unit, owner)
	return "%s %s\nHP %d  ATK %d" % [stars(unit["star"]), data["short"], stats["max_hp"], stats["attack"]]


func unit_tooltip(unit, owner: Dictionary) -> String:
	if unit == null:
		return ""
	var data: Dictionary = UNITS[unit["key"]]
	var stats := get_unit_stats(unit, owner)
	var traits := join_strings(get_unit_traits(unit), ", ")
	var items := []
	for item_key in unit["items"]:
		items.append(EQUIPMENT[item_key]["name"])
	var item_text := "No equipment" if items.is_empty() else join_strings(items, ", ")
	return "%s\n%s\nHP %d | ATK %d | ARM %d | SPD %.2f\nTraits: %s\n%s" % [
		data["name"],
		data["weapon"],
		stats["max_hp"],
		stats["attack"],
		stats["armor"],
		stats["speed"],
		traits,
		item_text
	]


func stars(count: int) -> String:
	var value := ""
	for _i in range(count):
		value += "*"
	return value


func card_color(card: Dictionary) -> String:
	if card["type"] == "unit":
		return UNITS[card["key"]]["color"]
	if card["type"] == "equipment":
		return "#604a36"
	return "#4e4930"


func add_log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 42:
		log_lines.pop_front()


func join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text


func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func add_stat(parent: GridContainer, label_text: String) -> Label:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(106, 54)
	box.add_theme_stylebox_override("panel", make_style("#17100c", "#4b3828", 7))
	parent.add_child(box)

	var stack := VBoxContainer.new()
	box.add_child(stack)

	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.html("#b9a88d"))
	stack.add_child(label)

	var value := Label.new()
	value.text = "-"
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color.html("#f8ecd2"))
	stack.add_child(value)
	return value


func add_match_stat(parent: HBoxContainer, label_text: String) -> Label:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", make_style("#17100c", "#4b3828", 7))
	parent.add_child(box)

	var stack := VBoxContainer.new()
	box.add_child(stack)

	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.html("#b9a88d"))
	stack.add_child(label)

	var value := Label.new()
	value.text = "-"
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color.html("#f8ecd2"))
	stack.add_child(value)
	return value


func make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.html("#f8ecd2"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func make_small_label(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.html("#b9a88d"))
	return label


func make_style(bg_hex: String, border_hex: String, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.html(bg_hex)
	style.border_color = Color.html(border_hex)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func stylize_button(button: Button, bg_hex: String, border_hex: String, dark_text: bool = false) -> void:
	button.add_theme_stylebox_override("normal", make_style(bg_hex, border_hex, 7))
	button.add_theme_stylebox_override("hover", make_style(lighten_hex(bg_hex, 0.1), "#f0cc73", 7))
	button.add_theme_stylebox_override("pressed", make_style(darken_hex(bg_hex, 0.1), "#f0cc73", 7))
	button.add_theme_stylebox_override("disabled", make_style("#24201b", "#4b3828", 7))
	button.add_theme_color_override("font_color", Color.html("#25160a") if dark_text else Color.html("#f8ecd2"))
	button.add_theme_color_override("font_disabled_color", Color.html("#7e715f"))
	button.add_theme_font_size_override("font_size", 14)


func lighten_hex(hex: String, amount: float) -> String:
	var color := Color.html(hex)
	color = color.lightened(amount)
	return "#" + color.to_html(false)


func darken_hex(hex: String, amount: float) -> String:
	var color := Color.html(hex)
	color = color.darkened(amount)
	return "#" + color.to_html(false)
