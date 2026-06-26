extends PanelContainer
class_name CombatLogPanel

const MAX_LINES := 12

var log_label: RichTextLabel
var lines: Array[String] = []

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(320, 124)
	_apply_panel_style()

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	add_child(layout)

	var title := Label.new()
	title.text = "COMBAT LOG"
	title.add_theme_color_override("font_color", Color(0.95, 0.83, 0.48, 1.0))
	layout.add_child(title)

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = false
	log_label.bbcode_enabled = false
	log_label.custom_minimum_size = Vector2(300, 92)
	log_label.add_theme_color_override("default_color", Color(0.90, 0.88, 0.78, 1.0))
	layout.add_child(log_label)
	clear_log()


func clear_log() -> void:
	lines.clear()
	_add_raw("Waiting for battle...")


func add_line(message: String) -> void:
	if lines.size() == 1 and lines[0] == "Waiting for battle...":
		lines.clear()
	_add_raw(message)


func _add_raw(message: String) -> void:
	lines.append(message)
	while lines.size() > MAX_LINES:
		lines.remove_at(0)
	_refresh()


func _refresh() -> void:
	if log_label == null:
		return
	var output := ""
	for index in range(lines.size()):
		if index > 0:
			output += "\n"
		output += lines[index]
	log_label.text = output


func _apply_panel_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.09, 0.10, 0.10, 1.0)
	panel.border_color = Color(0.44, 0.39, 0.30, 1.0)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	panel.content_margin_left = 10
	panel.content_margin_right = 10
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	add_theme_stylebox_override("panel", panel)
