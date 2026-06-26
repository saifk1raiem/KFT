extends RefCounted
class_name CombatResolver

const MAX_EXCHANGES := 35

static func simulate(player_units: Array[RuntimeUnit], enemy_units: Array[RuntimeUnit]) -> Dictionary:
	var log: Array[String] = []
	_prepare_team(player_units)
	_prepare_team(enemy_units)
	_apply_team_bonuses(player_units, log, "Player")
	_apply_team_bonuses(enemy_units, log, "Enemy")

	var exchanges := 0
	for exchange in range(1, MAX_EXCHANGES + 1):
		exchanges = exchange
		if _living(player_units).is_empty() or _living(enemy_units).is_empty():
			break
		_attack_side(player_units, enemy_units, log)
		if _living(enemy_units).is_empty():
			break
		_attack_side(enemy_units, player_units, log)

	var player_alive := _living(player_units).size()
	var enemy_alive := _living(enemy_units).size()
	var winner := "draw"
	if player_alive > enemy_alive:
		winner = "player"
	elif enemy_alive > player_alive:
		winner = "enemy"

	return {
		"winner": winner,
		"exchanges": exchanges,
		"player_alive": player_alive,
		"enemy_alive": enemy_alive,
		"log": log
	}


static func _prepare_team(units: Array[RuntimeUnit]) -> void:
	for unit in units:
		if unit == null:
			continue
		unit.clear_combat_modifiers()


static func _apply_team_bonuses(units: Array[RuntimeUnit], log: Array[String], label: String) -> void:
	var synergy: Dictionary = SynergySystem.calculate(units)
	var active: Dictionary = synergy["active"] as Dictionary

	for unit in units:
		if unit == null:
			continue
		if active.has(&"Guardian"):
			unit.bonus_armor += int(active[&"Guardian"]) * 4
		if active.has(&"Infantry"):
			unit.bonus_health += int(active[&"Infantry"]) * 35
		if active.has(&"Archer") and unit.definition.has_class(&"Archer"):
			unit.bonus_damage += int(active[&"Archer"]) * 7
		if active.has(&"Commander"):
			unit.bonus_damage += int(active[&"Commander"]) * 4
			unit.bonus_armor += int(active[&"Commander"]) * 2
		unit.start_combat()

	if not active.is_empty():
		log.append("%s active doctrines: %s" % [label, SynergySystem.summary(units)])


static func _attack_side(attackers: Array[RuntimeUnit], defenders: Array[RuntimeUnit], log: Array[String]) -> void:
	var active_attackers := _living(attackers)
	active_attackers.sort_custom(_sort_by_speed)

	for attacker in active_attackers:
		var targets := _living(defenders)
		if targets.is_empty():
			return
		var target := _choose_target(attacker, targets)
		var damage := _calculate_damage(attacker, target)
		target.receive_damage(damage)
		log.append("%s hits %s for %d" % [attacker.display_label(), target.display_label(), damage])


static func _choose_target(attacker: RuntimeUnit, targets: Array[RuntimeUnit]) -> RuntimeUnit:
	if attacker.definition.has_class(&"Assassin"):
		return _lowest_health(targets)

	if attacker.definition.has_class(&"Cavalry"):
		for target in targets:
			if target.definition.has_class(&"Archer") or target.definition.has_class(&"Support"):
				return target

	if attacker.definition.has_class(&"Spears"):
		for target in targets:
			if target.definition.has_class(&"Cavalry"):
				return target

	return targets[0]


static func _lowest_health(units: Array[RuntimeUnit]) -> RuntimeUnit:
	var selected: RuntimeUnit = units[0]
	for unit: RuntimeUnit in units:
		if unit.current_health < selected.current_health:
			selected = unit
	return selected


static func _calculate_damage(attacker: RuntimeUnit, target: RuntimeUnit) -> int:
	var damage := float(attacker.attack_damage())

	if attacker.definition.has_class(&"Spears") and target.definition.has_class(&"Cavalry"):
		damage *= 1.85
	if attacker.definition.has_class(&"Cavalry") and (target.definition.has_class(&"Archer") or target.definition.has_class(&"Support")):
		damage *= 1.45
	if attacker.definition.has_class(&"Duelist") and target.definition.has_class(&"Guardian"):
		damage *= 1.35
	if attacker.definition.has_class(&"Assassin") and target.current_health <= int(float(target.max_health()) * 0.45):
		damage *= 1.6
	if attacker.definition.has_class(&"Siege") and target.definition.has_class(&"Guardian"):
		damage *= 1.45

	var mitigated: float = damage * 100.0 / float(100 + maxi(0, target.armor()))
	return maxi(1, int(round(mitigated)))


static func _living(units: Array[RuntimeUnit]) -> Array[RuntimeUnit]:
	var alive: Array[RuntimeUnit] = []
	for unit in units:
		if unit != null and unit.is_alive():
			alive.append(unit)
	return alive


static func _sort_by_speed(a: RuntimeUnit, b: RuntimeUnit) -> bool:
	return a.definition.attack_speed > b.definition.attack_speed
