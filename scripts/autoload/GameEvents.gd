extends Node

signal gold_changed(gold: int)
signal level_changed(level: int, xp: int)
signal phase_changed(phase: int)
signal shop_rolled(units: Array)
signal unit_bought(unit: RuntimeUnit)
signal bench_changed()
signal board_changed()
signal combat_log(message: String)
signal status_message(message: String)

