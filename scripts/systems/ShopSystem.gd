extends RefCounted
class_name ShopSystem

const SHOP_SIZE := 5

var current_shop: Array[UnitDefinition] = []

func roll(level: int) -> Array[UnitDefinition]:
	current_shop = UnitDatabase.roll_shop(level, SHOP_SIZE)
	GameEvents.shop_rolled.emit(current_shop)
	return current_shop


func remove_unit(unit_id: StringName) -> void:
	for index in range(current_shop.size()):
		if current_shop[index].id == unit_id:
			current_shop.remove_at(index)
			GameEvents.shop_rolled.emit(current_shop)
			return

