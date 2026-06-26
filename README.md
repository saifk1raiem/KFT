# Iron Draft

Iron Draft is a Godot 4 2D auto-battler scaffold inspired by TFT-style drafting, positioning, economy, and counter play.

## Run

Open this folder in Godot 4. The main scene is:

`res://scenes/main/Main.tscn`

There are no third-party Godot addons or package dependencies yet. The project uses plain GDScript, JSON data, and built-in Godot UI nodes.

## Structure

- `data/units`: unit roster data loaded by `UnitDatabase`.
- `data/traits`: origins and classes for designers to tune.
- `scenes/board`: board and slot UI scenes.
- `scenes/game`: the root playable game loop scene.
- `scenes/ui`: HUD, bench, shop, and shop card scenes.
- `scenes/units`: future animated unit pawn scene.
- `scripts/autoload`: global event bus and unit data loader.
- `scripts/combat`: deterministic combat resolver.
- `scripts/core`: enums and shared constants.
- `scripts/data`: typed data models.
- `scripts/systems`: economy, shop, roster, trait, and enemy systems.

## Current Loop

1. Buy units from the shop.
2. Select a bench unit.
3. Click a player-side board slot to deploy it.
4. Start battle to simulate combat against a generated enemy army.
5. End round for income and a fresh shop.

