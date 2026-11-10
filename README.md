# Techie Crafting Overhaul

Cyberpunk 2077 (2.5) mod. Adds three Technical Ability perks to the Tech perk tree, all built around disassembly.

[한국어](README.ko.md)

| Tech | Perk | Effect |
|---|---|---|
| 9  | If Johnny Were a Techie... | Disassembling a normal weapon teaches its crafting spec at the same tier. |
| 15 | Should've Been Removable | Weapon mods can be removed and swapped freely. Disassembly returns attached mods. |
| 20 | Detail Rigging | Craft a replica of a Tier 5+ iconic weapon once per weapon type. |

## Requirements

| Component | Version |
|---|---|
| Cyberpunk 2077 | 2.5 or later |
| [RED4ext](https://github.com/WopsS/RED4ext) | 1.31.0 or later |
| [redscript](https://github.com/jac3km4/redscript) | 0.5.32 or later |
| [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) | latest 2.5-compatible |
| [Codeware](https://github.com/psiberx/cp2077-codeware) | latest 2.5-compatible |
| [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) | 1.0.1 or later |

Perk Addition Framework is required for the perks to appear as nodes in the Tech tree. Without it the perks activate by Technical Ability level.
Configuration is a YAML file. With [Mod Settings](https://github.com/jackhumbert/mod_settings) installed the same options are also available in the in-game settings menu (optional). ArchiveXL is not used.

## Installation

1. Manual
Copy the `r6` folder into the game directory.

```
Cyberpunk 2077/
  r6/scripts/TechieCraftingOverhaul/*.reds
  r6/tweaks/TechieCraftingOverhaul/*.yaml
```

2. Mod manager (recommended)
Install the downloaded zip as is with your mod manager.

Uninstalling: specs learned through this mod (tier specs, replica specs) are stored in the save. After removing the mod the crafting menu can no longer find those entries. This is the same constraint as any other spec-adding mod.

## Perk tree placement

| Perk | Tier | Prerequisite |
|---|---|---|
| If Johnny Were a Techie... | Adept (9) | none |
| Should've Been Removable | Expert (15) | If Johnny Were a Techie... |
| Detail Rigging | Master (20) | Should've Been Removable |

The three nodes form a chain in the row-2 right-hand area of the Tech tree, using connection pairs defined in the vanilla layout. Perks 15 and 20 sit in the row-2 area but unlock at Tech 15 and 20 as set by their tier records.

With `perkMode: attribute` (or without the framework) a perk activates once Technical Ability reaches 9 / 15 / 20.

## Perk details

### If Johnny Were a Techie... (Tech 9)

- Disassembling a normal weapon (not iconic, replica or quest item) adds the weapon model's spec at the same tier as the disassembled weapon (a Tier 2 weapon gives a Tier 2 spec).
- Disassembling a skin variant (Pimp, Neon, Military) still teaches the default-skin spec.
- Crafting costs follow vanilla values. Tiers 1 to 5 (plus variants included) use the vanilla spec cost of the same quality (30 components of that tier). Tier 5+ adds the iconic upgrade cost (75 Tier 5 components) and Tier 5++ adds the 5+ to 5++ upgrade cost on top (200 Tier 5 components).

  | Tier | Cost |
  |---|---|
  | 1, 1+ ... 4, 4+ | 30 components of that tier |
  | 5 | 30 Tier 5 components |
  | 5+ | 105 Tier 5 components |
  | 5++ | 305 Tier 5 components |
- If a normal-weapon spec with the same name and quality is already known, that tier is not learned.
- Crafted weapons use the default skin with random scope/mod slots removed.

### Should've Been Removable (Tech 15)

- Removal: mods can be unequipped from any weapon. Removed parts return to the inventory through the vanilla path.
- Swap: vanilla destroys the replaced mod. With the perk, one copy of that mod is returned.
- Disassembly: attached mods, scopes and muzzles are added to the disassembly result.
- The base weapon consumed by Detail Rigging goes through the same recovery logic.

### Detail Rigging (Tech 20)

- A replica spec is prepared for every iconic weapon. A replica is a copy without the quest-item flag and the pickup quest reaction. Modded weapons are included. Weapons whose behaviour is bound to quest scripting (Skippy: voice lines, mode switching and the quest hand-in; Erebus: the Blackwall haunting) and the quest-only sniper-nest Rasetsu are on the default exclusion list (`replicaExcluded`).
- When the crafting menu opens, a replica spec appears for every Tier 5+ original iconic in the inventory (perk active, type not yet replicated). It is hidden when the original leaves the inventory or the type has been replicated.
- Crafting conditions (all): perk active / original owned (Tier 5+) / base weapon(s) owned when a mapping exists (Tier 5+, one per mapping entry, not equipped, not quest items) / configured component amount / weapon type not yet replicated / original is not itself a replica. Iconics without any base mapping cost components only.
- A base weapon counts if it has the same weapon type and display name and is not iconic.
- Recipes with two or more weapon ingredients, or several copies of one weapon, show the extra weapons (or the counted weapon) as regular ingredient rows with their counts.
- The cost is set by a preset (`replicaPreset`).

  | Preset | Cost |
  |---|---|
  | `base` (default) | base weapon + 200 Tier 5 components |
  | `parts` | 200 Tier 5 components, no base weapon |
  | `fusion` | two extra copies of the same original iconic (one original is kept, no components) |
  | `custom` | the individual knobs (base weapon on/off, extra originals, component amount) |
- The original is kept, the base weapon is consumed (treated as disassembly, mods recovered) and the replica is granted. The replica matches the original's upgrade count, quality, plus stats and unique effects.
- The replication log (once per weapon type) is stored in the save and is not reset by disassembling the replica.
- Replicas cannot be disassembled by default, like any iconic. `replicaDisassembleAllowed: true` makes them the one exception.

### Base weapon map (`TCO_BaseWeaponMap.yaml`)

- 119 vanilla iconic entries generated from the 2.5 tweak sources. Most point to the parent preset (`Preset_<Weapon>_Default`) and can be set manually. Listing two weapons requires both; listing the same weapon twice requires two of it.
- Iconics missing from the list (modded weapons) are matched automatically: same weapon type and same `friendlyName` `_Default` preset.
- Format:
  ```yaml
  TCO.BaseMap.Items.Preset_Silverhand_3516:
    $type: Craftable
    craftableItem: [ Items.Preset_Overture_Default ]
  ```
- Per-weapon cost override: a CraftingPackage named `TCO.ReplicaCost.<iconic record>` replaces the preset for that weapon. Weapon ingredients are consumed as base weapons (the iconic itself is allowed), everything else as components. An example is at the end of `TCO_BaseWeaponMap.yaml`.

## Configuration (`TCO_Config.yaml`)

With Mod Settings installed, the options marked ✓ in the Menu column take their value from the in-game settings menu (Mod Settings → Techie Crafting Overhaul) and the same keys in the YAML file are ignored. Changes made in the menu apply immediately, without a restart. Unmarked options, the base weapon map and per-weapon cost overrides are YAML only. Without Mod Settings everything is read from the YAML file.

| Key | Default | Menu | Description |
|---|---|---|---|
| `perkMode` | auto | | `auto`: tree nodes when Perk Addition Framework is present, attribute thresholds otherwise. `tree` / `attribute` force a mode. |
| `perk9Enabled` / `perk15Enabled` / `perk20Enabled` | true | ✓ | Per-perk toggle |
| `perk9Attribute` / `perk15Attribute` / `perk20Attribute` | 9 / 15 / 20 | ✓ | Technical Ability required in attribute mode (tree mode uses vanilla tiers 9/15/20) |
| `replicaPreset` | base | ✓ | Replica cost preset: `base` / `parts` / `fusion` / `custom` |
| `replicaUseBaseWeapon` / `replicaOriginalCopies` | true / 0 | ✓ | `custom` preset knobs: require base weapon, extra originals consumed |
| `replicaMaterialItem` | `Items.LegendaryMaterial1` | | Component consumed by replication |
| `replicaMaterialAmount` | 200 | ✓ | Component amount (`base` / `parts` / `custom`) |
| `replicaRequiredTier` | 8 | ✓ | Minimum EffectiveTier of original and base weapon (8 = Tier 5, 9 = 5+, 10 = 5++) |
| `replicaDisassembleAllowed` | false | ✓ | Allow disassembling replicas |
| `replicaExcluded` | Skippy, Erebus, the sniper-nest Rasetsu | | Iconic weapons that get no replica spec |
| `recipeTierMode` | equal | ✓ | Perk 9 scope: `equal` same tier / `upto` same and lower / `all` |
| `notifications` | true | ✓ | On-screen notifications |
| `debugLog` | false | ✓ | Debug messages: why a spec was skipped and what the replica list found when the crafting menu opens, shown as on-screen notifications |

## Files

```
r6/scripts/TechieCraftingOverhaul/
  TCO_Core.reds            config access, strings (KR/EN), helpers, ScriptableSystem (perk checks, replication log)
  TCO_Localization.reds    Codeware localization: perk names and descriptions, settings menu labels (KR/EN)
  TCO_Tweaks.reds          TweakXL ScriptableTweak: tier specs, replica specs, perk tree attachment
  TCO_Perk9_Recipes.reds   disassembly hook → spec learning
  TCO_Perk15_Mods.reds     unequip check, swap preservation, UI unblocking, disassembly recovery
  TCO_Perk20_Replica.reds  replica spec sync, condition checks, replica crafting flow
  TCO_UI.reds              replica name suffix, base weapon display in the crafting panel
  TCO_Settings.reds        Mod Settings integration (optional): in-game settings menu entries
r6/tweaks/TechieCraftingOverhaul/
  TCO_Config.yaml          configuration
  TCO_BaseWeaponMap.yaml   iconic → base weapon (all vanilla iconics)
  TCO_ModelMap.yaml        perk 9 model/skin exceptions
  TCO_Perks.yaml           three Tech tree perk nodes (NewPerks.TCO_Tech_*)
  TCO_Icons.yaml           perk icon overrides (template for a custom atlas, commented out)
```

## Limitations

- Perk nodes depend on Perk Addition Framework. Other perk-adding mods using the same slots conflict (duplicate-slot warning in the framework log).
- Perks 15 and 20 are placed in the row-2 area of the tree. Their unlock requirements are 15 and 20 regardless of position.
- Vanilla 2.5 blocks disassembling iconic weapons. Iconics are therefore never a source for perk 9. Replicas are the only exception.
- Where weapon internal names cannot be read, the default-skin check falls back to the skin tag.
- The crafting UI lists the base weapon as "×1" and does not show the tier condition. The condition is conveyed by button state and notifications.

## Credits

- Game scripts and tweak sources: CDPR REDmod sources (CDPR-Modding-Documentation/Cyberpunk-Scripts, Cyberpunk-Tweaks, v2.5)
- Perk enum extension: [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) by JonnesTT ([GitHub](https://github.com/JonnesTT/Cyberpunk_PerkAdditionFramework))
- TweakXL / Codeware: psiberx

## License

CC0 1.0 (public domain). Use, modify and redistribute freely, no attribution required. Full text in [LICENSE](LICENSE).
