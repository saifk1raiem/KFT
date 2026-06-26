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
var status_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	gold_label = _add_label(row, "Gold: 0")
	level_label = _add_label(row, "Level: 1")
	round_label = _add_label(row, "Round: 1")
	phase_label = _add_label(row, "Prep")

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
	add_child(status_label)


func update_state(gold: int, level: int, xp: int, round_number: int, phase: int) -> void:
	if gold_label == null:
		return
	gold_label.text = "Gold: %d" % gold
	level_label.text = "Level: %d XP: %d" % [level, xp]
	round_label.text = "Round: %d" % round_number
	phase_label.text = "Phase: %s" % IronEnums.phase_name(phase)


func set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _add_label(parent: Control, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.custom_minimum_size = Vector2(120, 28)
	parent.add_child(label)
	return label


func _add_button(parent: Control, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(112, 34)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_refresh_pressed() -> void:
	refresh_shop_requested.emit()


func _on_buy_xp_pressed() -> void:
	buy_xp_requested.emit()


func _on_start_battle_pressed() -> void:
	start_battle_requested.emit()


func _on_end_round_pressed() -> void:
	end_round_requested.emit()

