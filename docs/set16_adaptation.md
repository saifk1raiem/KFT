# Lore & Legends Adaptation Notes

The referenced TFT Set 16 PDF points to a few core ideas worth adapting into Iron Draft without copying Riot's champions or lore:

- A base roster plus match-local unlockable units.
- Unlocks triggered by combat, economy, level, round, or trait routing.
- Newly unlocked units first appearing in the rightmost shop slot.
- Skipped unlock offers decaying in future appearance rate.
- Strong vertical openings that can transition into rarer late-game cap pieces.
- Stage-based player damage so greedy unlock routing has real risk.

Iron Draft now uses those ideas with original medieval soldiers:

- `data/units/iron_draft_units.json` is the base roster.
- `data/units/iron_draft_unlockables.json` is the unlockable roster.
- `UnlockSystem` owns personal match unlocks, pending right-slot offers, and skipped-offer decay.
- `ShopSystem` rolls base/personal shops and reserves the rightmost slot for fresh unlocks.
- `GameController` evaluates unlocks from the current deployed traits, gold, level, round, and wins.

