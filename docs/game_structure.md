# Game Structure

## Core Flow

Iron Draft is organized around a small TFT-like loop:

1. Prep phase: buy units, manage bench, and position soldiers.
2. Combat phase: the board resolves a deterministic auto-battle.
3. Results phase: rewards are applied and the next round can begin.

## Main Systems

- `GameController`: owns the round loop and wires the UI to the systems.
- `EconomySystem`: tracks gold, level, XP, income, shop refreshes, and XP buys.
- `ShopSystem`: rolls unit offers from `UnitDatabase`.
- `ArmyRoster`: owns bench units and deployed player units.
- `EnemyRosterBuilder`: creates round-scaled enemy teams.
- `CombatResolver`: resolves counter-based combat.
- `SynergySystem`: counts origins/classes and activates trait breakpoints.

## Data

The playable roster is in `res://data/units/iron_draft_units.json`.
Each entry becomes a `UnitDefinition` at runtime.

Important unit fields:

- `cost`: 1 to 5.
- `origin`: cultural background.
- `classes`: gameplay traits.
- `role`: short battlefield job.
- `strengths` and `weaknesses`: design intent for counter logic.
- `max_health`, `attack_damage`, `attack_range`, `attack_speed`, `armor`.
