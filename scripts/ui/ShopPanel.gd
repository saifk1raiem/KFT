extends HBoxContainer
class_name ShopPanel

signal unit_buy_requested(unit_id: StringName)

const CARD_SCENE := preload("res://scenes/ui/UnitCard.tscn")

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_shop(units: Array[UnitDefinition]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for unit in units:
		var card := CARD_SCENE.instantiate() as UnitCard
		card.set_unit_definition(unit)
		card.buy_requested.connect(_on_card_buy_requested)
		add_child(card)


func _on_card_buy_requested(unit_id: StringName) -> void:
	unit_buy_requested.emit(unit_id)
