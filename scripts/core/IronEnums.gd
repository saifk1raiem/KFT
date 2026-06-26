extends RefCounted
class_name IronEnums

enum GamePhase { PREP, COMBAT, RESULTS }

const SIDE_PLAYER: StringName = &"player"
const SIDE_ENEMY: StringName = &"enemy"

const SHOP_ODDS: Dictionary = {
	1: {1: 100, 2: 0, 3: 0, 4: 0, 5: 0},
	2: {1: 75, 2: 25, 3: 0, 4: 0, 5: 0},
	3: {1: 55, 2: 35, 3: 10, 4: 0, 5: 0},
	4: {1: 40, 2: 35, 3: 20, 4: 5, 5: 0},
	5: {1: 25, 2: 35, 3: 30, 4: 10, 5: 0},
	6: {1: 15, 2: 30, 3: 35, 4: 18, 5: 2},
	7: {1: 10, 2: 25, 3: 35, 4: 25, 5: 5},
	8: {1: 5, 2: 20, 3: 35, 4: 30, 5: 10},
	9: {1: 0, 2: 15, 3: 30, 4: 35, 5: 20}
}

static func shop_odds_for_level(level: int) -> Dictionary:
	var clamped_level: int = clampi(level, 1, 9)
	return SHOP_ODDS[clamped_level] as Dictionary


static func phase_name(phase: int) -> String:
	match phase:
		GamePhase.PREP:
			return "Prep"
		GamePhase.COMBAT:
			return "Combat"
		GamePhase.RESULTS:
			return "Results"
		_:
			return "Unknown"
