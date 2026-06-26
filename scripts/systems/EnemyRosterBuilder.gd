extends RefCounted
class_name EnemyRosterBuilder

static func build(round_number: int, player_level: int) -> Array[RuntimeUnit]:
	var target_size := clampi(2 + int(round_number / 2), 2, 7)
	var roll_level := clampi(player_level + int(round_number / 4), 1, 9)
	var definitions := UnitDatabase.roll_shop(roll_level, target_size)
	var units: Array[RuntimeUnit] = []

	for definition in definitions:
		var unit := RuntimeUnit.new(definition, IronEnums.SIDE_ENEMY)
		if round_number >= 5 and definition.cost <= 2:
			unit.star_level = 2
		if round_number >= 9 and definition.cost <= 3:
			unit.star_level = 2
		units.append(unit)

	return units

