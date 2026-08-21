# Changelog

## 1.4.4

### Changed

- Memoized displayed item levels so a decorated link resolves its tooltip once instead of once for the display and again for the comparison.
- Cached equipped-slot lookups, keyed by the equipped item link so a gear change invalidates them without an event. Loot bursts no longer rebuild the same tooltips for every message.
- Item levels are only memoized once the client has fully cached the item, and are dropped on level-up or a world change so level-scaled items cannot go stale.

## 1.4.3

### Fixed

- Fixed incorrect item-level deltas when WoW 12.0 returns a pre-squish API level for an item whose tooltip shows the squished level.
- Item-level displays and comparisons now prefer the client tooltip's displayed level, and unreliable comparisons fall back to `Item Level Unknown`.

## 1.4.2

### Changed

- Refined loot evaluation into distinct suitability results: `Suitable`, `Wrong Armor Type`, `Wrong Primary Stat`, `Not for Current Spec` and `Cannot Equip`.
- Clarified that armor-type and primary-stat mismatches are reported separately from specialization mismatches.
- Renamed the ambiguous `Weapon Setup` comparison label to `Different Weapon Setup`.

## 1.4.1

### Changed

- Split the addon implementation into focused modules without changing user-facing behavior or saved settings.
- Updated the test loader, release packaging and installation documentation for the modular file layout.

## 1.4.0

### Added

- Added color-coded loot evaluation labels after the existing item details.
- Added `Suitable`, `Not for Current Spec` and `Cannot Equip` checks based on the current character, specialization, primary stat and preferred armor type.
- Added equipped item-level comparisons with `iLvl +N`, `iLvl -N` and `Same iLvl` labels.
- Added correct lower-slot comparisons for rings and trinkets.
- Added `Empty Slot` and `Item Level Unknown` states so missing equipment or uncached data is never presented as a guessed upgrade.
- Added a conservative `Weapon Setup` label for one-hand/two-hand transitions that cannot be represented by a reliable single-slot comparison.
- Added `/sli suitable [on|off]` and `/sli upgrade [on|off]` commands.

### Behavior

- Loot evaluation labels are appended only after the complete existing output. The established type, slot, item level, item link, secondary-stat and tertiary-stat order is unchanged.
- Character-specific evaluation is shown only for loot messages. Gear linked in ordinary chat keeps the previous enhancement format.
- Every status uses both English text and a distinct high-contrast color for readability.
- Item-level upgrade decisions require detailed item-level data; the base item-level fallback is still used for the original display but never for a guessed comparison.

### Compatibility

- Updated for WoW Retail Interface `120100`.
- Added support for the modern `C_SpecializationInfo` API with a legacy global API fallback.
