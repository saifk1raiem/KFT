extends VBoxContainer
class_name HUD

signal start_battle_requested()
signal end_round_requested()
signal refresh_shop_requested()
signal buy_xp_requested()

var gold_label: Label
var level_label: Label
var round_label: Label
var phase_label: Label
var health_label: Label
var status_label: Label
var doctrine_label: Label
var unlock_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "IRON DRAFT - TEXT PROTOTYPE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.83, 0.48, 1.0))
	add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	gold_label = _add_label(row, "Gold: 0")
	level_label = _add_label(row, "Level: 1")
	round_label = _add_label(row, "Round: 1")
	phase_label = _add_label(row, "Prep")
	health_label = _add_label(row, "HP: 100")

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_add_button(row, "Refresh 2G", Callable(self, "_on_refresh_pressed"))
	_add_button(row, "Buy XP 4G", Callable(self, "_on_buy_xp_pressed"))
	_add_button(row, "Start Battle", Callable(self, "_on_start_battle_pressed"))
	_add_button(row, "End Round", Callable(self, "_on_end_round_pressed"))

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "Buy units, deploy them on the lower half, then start battle."
	status_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.83, 1.0))
	add_child(status_label)

	doctrine_label = Label.new()
	doctrine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doctrine_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.72, 1.0))
	add_child(doctrine_label)

	unlock_label = Label.new()
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_label.add_theme_color_override("font_color", Color(0.86, 0.76, 0.48, 1.0))
	add_child(unlock_label)


func update_state(gold: int, level: int, xp: int, round_number: int, phase: int, player_health: int, rival_health: int, stage: int) -> void:
	if gold_label == null:
		return
	gold_label.text = "Gold: %d" % gold
	level_label.text = "Level: %d XP: %d" % [level, xp]
	round_label.text = "Stage %d Round %d" % [stage, round_number]
	phase_label.text = "Phase: %s" % IronEnums.phase_name(phase)
	health_label.text = "HP: %d / Rival %d" % [player_health, rival_health]


func set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func set_doctrine(message: String) -> void:
	if doctrine_label != null:
		doctrine_label.text = message


func set_unlocks(message: String) -> void:
	if unlock_label != null:
		unlock_label.text = message


func _add_label(parent: Control, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.custom_minimum_size = Vector2(120, 28)
	label.add_theme_color_override("font_color", Color(0.92, 0.89, 0.78, 1.0))
	parent.add_child(label)
	return label


func _add_button(parent: Control, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(112, 34)
	_apply_button_style(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.24, 0.25, 0.23, 1.0)
	normal.border_color = Color(0.72, 0.63, 0.42, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.33, 0.34, 0.30, 1.0)
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.16, 0.17, 0.16, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color(0.96, 0.91, 0.76, 1.0))


func _on_refresh_pressed() -> void:
	refresh_shop_requested.emit()


func _on_buy_xp_pressed() -> void:
	buy_xp_requested.emit()


func _on_start_battle_pressed() -> void:
	start_battle_requested.emit()


func _on_end_round_pressed() -> void:
	end_round_requested.emit()
