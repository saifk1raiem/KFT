extends RefCounted
class_name ShopSystem

const SHOP_SIZE := 5

var current_shop: Array[UnitDefinition] = []
var current_rightmost_unlock_id: StringName = &""

func roll(level: int, unlock_system: UnlockSystem = null) -> Array[UnitDefinition]:
	current_rightmost_unlock_id = &""
	if unlock_system != null:
		unlock_system.begin_roll()

	var rightmost_offer: UnitDefinition = null
	if unlock_system != null:
		rightmost_offer = unlock_system.next_rightmost_offer()

	var normal_slot_count := SHOP_SIZE
	if rightmost_offer != null:
		normal_slot_count = SHOP_SIZE - 1

	if unlock_system != null:
		current_shop = UnitDatabase.roll_personal_shop(level, normal_slot_count, unlock_system)
	else:
		current_shop = UnitDatabase.roll_shop(level, normal_slot_count)

	if rightmost_offer != null:
		current_shop.append(rightmost_offer)
		current_rightmost_unlock_id = rightmost_offer.id
		unlock_system.mark_offer_shown(rightmost_offer.id)

	GameEvents.shop_rolled.emit(current_shop)
	return current_shop


func remove_unit(unit_id: StringName, unlock_system: UnlockSystem = null) -> void:
	for index in range(current_shop.size()):
		if current_shop[index].id == unit_id:
			if unlock_system != null and current_shop[index].unlockable:
				unlock_system.mark_offer_bought(unit_id)
			current_shop.remove_at(index)
			GameEvents.shop_rolled.emit(current_shop)
			return
