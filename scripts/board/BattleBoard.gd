extends GridContainer
class_name BattleBoard

signal board_slot_pressed(grid_position: Vector2i)

const SLOT_SCENE := preload("res://scenes/board/BoardSlot.tscn")

@export var board_width := 8
@export var board_height := 4

var slots: Dictionary = {}

func _ready() -> void:
	columns = board_width
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
	build_board()


func build_board() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	slots.clear()

	for y in range(board_height):
		for x in range(board_width):
			var slot := SLOT_SCENE.instantiate() as BoardSlot
			var side := IronEnums.SIDE_ENEMY if y < int(board_height / 2) else IronEnums.SIDE_PLAYER
			var position := Vector2i(x, y)
			slot.setup(position, side)
			slot.slot_pressed.connect(_on_slot_pressed)
			add_child(slot)
			slots[position] = slot


func sync_units(player_board: Dictionary, enemies: Array[RuntimeUnit]) -> void:
	for slot_value: Variant in slots.values():
		var slot: BoardSlot = slot_value as BoardSlot
		slot.clear_unit()

	for position_key: Variant in player_board.keys():
		var position: Vector2i = Vector2i(position_key)
		if slots.has(position):
			var slot: BoardSlot = slots[position] as BoardSlot
			var unit: RuntimeUnit = player_board[position] as RuntimeUnit
			slot.set_unit(unit)

	var start_x: int = maxi(0, int((board_width - enemies.size()) / 2))
	for index: int in range(enemies.size()):
		var x: int = (start_x + index) % board_width
		var y: int = int(index / board_width)
		var position := Vector2i(x, y)
		if slots.has(position):
			enemies[index].board_position = position
			var slot: BoardSlot = slots[position] as BoardSlot
			slot.set_unit(enemies[index])


func is_player_position(position: Vector2i) -> bool:
	return position.y >= int(board_height / 2)


func _on_slot_pressed(position: Vector2i) -> void:
	board_slot_pressed.emit(position)
