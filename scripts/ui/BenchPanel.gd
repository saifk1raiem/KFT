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
		button.custom_minimum_size = Vector2(116, 66)
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
		_apply_bench_style(button, bench[index] != null)
		button.pressed.connect(_on_slot_pressed.bind(index))
		add_child(button)


func select(index: int) -> void:
	selected_index = index


func clear_selection() -> void:
	selected_index = -1


func _on_slot_pressed(index: int) -> void:
	selected_index = index
	bench_slot_selected.emit(index)


func _apply_bench_style(button: Button, occupied: bool) -> void:
	var base_color := Color(0.13, 0.17, 0.18, 1.0)
	if occupied:
		base_color = Color(0.18, 0.26, 0.20, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = Color(0.45, 0.42, 0.34, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.border_color = Color(0.86, 0.73, 0.38, 1.0)
	pressed_style.set_border_width_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("hover", pressed_style)
	button.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
