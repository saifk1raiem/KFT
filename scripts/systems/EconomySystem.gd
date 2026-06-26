extends RefCounted
class_name EconomySystem

const STARTING_GOLD := 10
const STARTING_LEVEL := 1
const SHOP_REFRESH_COST := 2
const BUY_XP_COST := 4
const XP_PER_BUY := 4
const MAX_LEVEL := 9

const XP_TO_LEVEL := {
	1: 2,
	2: 4,
	3: 6,
	4: 10,
	5: 18,
	6: 30,
	7: 46,
	8: 64
}

var gold := STARTING_GOLD
var level := STARTING_LEVEL
var xp := 0
var win_streak := 0
var loss_streak := 0

func can_afford(amount: int) -> bool:
	return gold >= amount


func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	GameEvents.gold_changed.emit(gold)
	return true


func gain(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	GameEvents.gold_changed.emit(gold)


func buy_xp() -> bool:
	if level >= MAX_LEVEL or not spend(BUY_XP_COST):
		return false
	add_xp(XP_PER_BUY)
	return true


func add_xp(amount: int) -> void:
	xp += maxi(0, amount)
	while level < MAX_LEVEL and xp >= int(XP_TO_LEVEL.get(level, 9999)):
		xp -= int(XP_TO_LEVEL[level])
		level += 1
	GameEvents.level_changed.emit(level, xp)


func award_round_income(round_number: int, won_last_round: bool) -> int:
	var base_income: int = 5
	var interest: int = mini(5, int(gold / 10))
	var streak_bonus: int = _update_streaks(won_last_round)
	var round_bonus: int = mini(3, int(round_number / 3))
	var total: int = base_income + interest + streak_bonus + round_bonus
	gain(total)
	return total


func _update_streaks(won: bool) -> int:
	if won:
		win_streak += 1
		loss_streak = 0
		return mini(3, int(win_streak / 2))
	loss_streak += 1
	win_streak = 0
	return mini(2, int(loss_streak / 2))
