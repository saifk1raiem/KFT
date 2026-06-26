extends HBoxContainer
class_name BenchPanel

signal bench_slot_selected(index: int)

var selected_index := -1

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_units(bench: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for index in range(bench.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(104, 64)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = index == selected_index
		if bench[index] == null:
			button.text = "Bench %d\nEmpty" % [index + 1]
			button.disabled = true
		else:
			var unit: RuntimeUnit = bench[index] as RuntimeUnit
			button.text = "Bench %d\n%s" % [index + 1, unit.display_label()]
			button.disabled = false
		button.pressed.connect(_on_slot_pressed.bind(index))
		add_child(button)


func select(index: int) -> void:
	selected_index = index


func clear_selection() -> void:
	selected_index = -1


func _on_slot_pressed(index: int) -> void:
	selected_index = index
	bench_slot_selected.emit(index)
