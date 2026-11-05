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

Perk Addition Framework is required for the perks to appear as nodes in the Tech tree. Without it the mod falls back to attribute thresholds (see `perkMode`).
ArchiveXL and Mod Settings are not used. Configuration is done in a YAML file.

## Installation

Copy the `r6` folder into the game directory.

```
Cyberpunk 2077/
  r6/scripts/TechieCraftingOverhaul/*.reds
  r6/tweaks/TechieCraftingOverhaul/*.yaml
```

Uninstalling: recipes learned through this mod (tier specs, replica specs) are stored in the save as record IDs. After removing the mod those entries can no longer be resolved by the crafting menu. This is the same constraint as any other recipe-adding mod.

## Perk tree placement

| Perk | Slot | Tier | Prerequisite |
|---|---|---|---|
| If Johnny Were a Techie... | `Right_Milestone_2` (row 2, right, milestone widget) | Adept (9) | none |
| Should've Been Removable | `Right_Perk_2_1` (row 2, right) | Expert (15) | perk 9 |
| Detail Rigging | `Right_Perk_2_3` (row 2, right) | Master (20) | perk 15 |

The three nodes form a chain in the row-2 right-hand area of the Tech tree, using connection pairs predefined in the vanilla layout. Perks 15 and 20 sit in the row-2 area but unlock at Tech 15 and 20 as set by their tier records. Their descriptions state the requirement.

Perks cost vanilla perk points. Refunds on attribute reset are handled by Perk Addition Framework.

With `perkMode: attribute` (or when the framework is missing), a perk is active once the Technical Ability attribute reaches the value in `perk9Attribute` / `perk15Attribute` / `perk20Attribute`.

## Perk details

### If Johnny Were a Techie... (Tech 9)

- Disassembling a normal weapon (not iconic, replica or quest item) adds the weapon model's crafting spec at the same tier as the disassembled weapon (a Tier 2 weapon adds a Tier 2 spec).
- Eleven tier records per model (1, 1+, 2, 2+, ... 5, 5+, 5++) are generated at load. `recipeTierMode` selects `equal` (same tier, default), `upto` (that tier and below) or `all`.
- Model resolution order: preset named `_Default` → `TCO_ModelMap.yaml` entry → `_Default` preset with the same display name → the disassembled preset itself. Skinned variants teach the default-skin spec.
- Crafting cost is read from vanilla records at load. Tiers 1 to 5 (plus variants included) use the vanilla recipe cost of the same quality (`Items.Small_<Quality>_Crafting_Materials_Weapon`, 30 components). Tier 5+ adds the iconic upgrade cost from Tier 5 to 5+ (`Upgrading.Legendary`, 75 Tier 5 components). Tier 5++ adds the 5+ to 5++ step on top (`Upgrading.LegendaryPlus`, 200 Tier 5 components).

  | Tier | Cost |
  |---|---|
  | 1, 1+ ... 4, 4+ | 30 components of that tier |
  | 5 | 30 Tier 5 components |
  | 5+ | 105 Tier 5 components |
  | 5++ | 305 Tier 5 components |
- A tier is skipped if a normal-weapon spec with the same name and quality is already known (shop specs `Items.Craftable_*`, other mods).
- Crafted weapons use the default skin with random scope/mod slots removed, like vanilla `Craftable_*` items.

### Should've Been Removable (Tech 15)

- Removal: `RPGManager.CanPartBeUnequipped` allows unequipping mods from any weapon, not only iconics. Removed parts go to the inventory through the vanilla `RemoveItemPart` path.
- Swap: `ItemModificationSystem.InstallItemPart` destroys the replaced mod in vanilla. With the perk, one part with the same record is returned. The inventory UI's "no empty slot" block (normal weapons) and the destruction warning popup (iconics) are skipped.
- Disassembly: `GetDisassemblyResultItems` adds attached mods, scopes and muzzles to the result list. `DummyPart` and the parent part are excluded.
- The base weapon consumed by Detail Rigging goes through the same recovery logic.

### Detail Rigging (Tech 20)

- At load, a replica record `<Iconic>_TCO_Replica` is created for every iconic weapon record (`Quest` tag removed, `OnLooted` quest-fact effect removed, `TCO_Replica` tag added). Modded iconics are included.
- Opening the crafting menu lists a replica spec for every Tier 5+ original iconic in the inventory (perk active, type not yet replicated). Materials are not a listing condition. Entries disappear when the original leaves the inventory or the type has been replicated.
- Crafting conditions (all): perk active; original owned (Tier 5+); base weapon(s) owned when a mapping exists (Tier 5+, one per mapping entry, not equipped, not quest items); configured component amount; weapon type not yet replicated; original is not itself a replica. Iconics without any base mapping cost components only.
- A base weapon is matched by model, not by exact record: the mapped record itself (`Preset_<Weapon>_Default`), weapons crafted from perk 9 specs, skin variants (Pimp / Neon / Military) and vanilla crafted weapons (`Craftable_*`) all count as long as they share the weapon type and display name and are not iconic. The ingredient row shows the number of usable base weapons.
- The vanilla panel has a single weapon ingredient slot. When a replica needs two base weapons (Malorian Arms 3516: Tamayura + Overture), the extra one is shown as a regular ingredient row.
- Replica records are fixed to Legendary quality, so the cost is exactly the base weapon plus the configured Tier 5 components. (A Random-quality record would make the game append Tier 2 to 5 components scaled to player level.)
- Result: original kept, base weapon(s) consumed (treated as disassembly, mods recovered), replica granted. The replica's upgrade count, quality and plus stats are matched to the original so both end at the same tier. Unique effects follow from the cloned record.
- The once-only rule is keyed by weapon type (display-name LocKey). The log is stored in the save and is not reset by disassembling the replica.
- Replicas can be disassembled despite the iconic tag (`replicaDisassembleAllowed`).

### Base weapon map (`TCO_BaseWeaponMap.yaml`)

- 119 entries covering vanilla iconics, generated from the 2.5 tweak sources. Most map to the parent preset (`Preset_<Weapon>_Default`). Twelve without a matching family are set manually (Malorian Arms 3516 → Tamayura `Preset_Kenshin_Default` + Overture, Caretaker's Spade → Hammer, Cottonmouth / Sir John / Tinker Bell → Baton, etc.).
- Quality variant records of an iconic (`Common_` / `Uncommon_` / `Rare_` / `Epic_` / `Legendary_<Iconic>`, which is what the player usually holds in 2.x) inherit the mapping of the record with the same display name (`Preset_<Iconic>`).
- Iconics missing from the table (modded weapons) are matched automatically: same weapon type and same `friendlyName` `_Default` preset.
- Format:
  ```yaml
  TCO.BaseMap.Items.Preset_Silverhand_3516:
    $type: Craftable
    craftableItem: [ Items.Preset_Kenshin_Default, Items.Preset_Overture_Default ]
  ```

## Configuration (`TCO_Config.yaml`)

| Key | Default | Description |
|---|---|---|
| `perkMode` | auto | `auto`: tree nodes if Perk Addition Framework is present, attribute thresholds otherwise. `tree` / `attribute` force a mode. |
| `perk9Enabled` / `perk15Enabled` / `perk20Enabled` | true | Per-perk toggle |
| `perk9Attribute` / `perk15Attribute` / `perk20Attribute` | 9 / 15 / 20 | Technical Ability required in attribute mode (tree mode uses vanilla tiers 9/15/20) |
| `replicaMaterialItem` | `Items.LegendaryMaterial1` | Component consumed by replication |
| `replicaMaterialAmount` | 200 | Component amount |
| `replicaRequiredTier` | 8 | Minimum EffectiveTier of original and base weapon (8 = Tier 5, 9 = 5+, 10 = 5++) |
| `replicaDisassembleAllowed` | true | Allow disassembling replicas |
| `recipeTierMode` | equal | Perk 9 scope: `equal` same tier / `upto` same and lower / `all` |
| `notifications` | true | On-screen notifications |
| `debugLog` | false | `[TCO]` debug output via `FTLog` and `ModLog(n"TechieCraftingOverhaul")`, plus an on-screen summary of the replica list sync when the crafting menu opens |

## Custom perk icons

Perk icons are `UIIcon` records (`atlasResourcePath` + `atlasPartName`) referenced by `NewPerk.perkIcon`. The default uses vanilla icons.

1. Prepare square PNGs with a white silhouette on a transparent background (the game tints them by state). File name = atlas part name.
2. In WolvenKit, build an `.inkatlas` + `.xbm` from the PNGs (for example `mod\tco\tco_perk_icons.inkatlas`) and pack to `archive/pc/mod/`. ArchiveXL is not needed.
3. In `TCO_Icons.yaml`, uncomment the `UIIcon.TCO_Perk*` records and the `perkIcon` overrides and set the path and part names.

Icons only change the image. Node shape and size are fixed by the slot widget.

## Files

```
r6/scripts/TechieCraftingOverhaul/
  TCO_Core.reds            config access, strings (KR/EN), helpers, ScriptableSystem (perk checks, replica log)
  TCO_Localization.reds    Codeware localization: perk names and descriptions (KR/EN)
  TCO_Tweaks.reds          TweakXL ScriptableTweak: tier spec records, replica records, perk tree attachment
  TCO_Perk9_Recipes.reds   disassembly hook → spec learning
  TCO_Perk15_Mods.reds     unequip check, swap preservation, UI unblocking, disassembly recovery
  TCO_Perk20_Replica.reds  replica spec sync, condition checks, replica crafting flow
  TCO_UI.reds              replica name suffix
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
- Perk icons reuse vanilla Tech icons unless a custom atlas is provided.
- `CraftingSystem.CanItemBeDisassembled` blocks `IconicWeapon` items in 2.5. Iconics are therefore never a source for perk 9. Replicas are the only exception.
- When record names (`TDBID.ToStringDEBUG`) cannot be read, the `_Default` check falls back to `visualTags == ["Default"]`.
- The crafting UI lists the base weapon as "×1" and does not display the tier condition. The condition is conveyed by button state and notifications.

## Credits

- Game scripts and tweak sources: CDPR REDmod sources (CDPR-Modding-Documentation/Cyberpunk-Scripts, Cyberpunk-Tweaks, v2.5)
- Perk enum extension: [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) by JonnesTT ([GitHub](https://github.com/JonnesTT/Cyberpunk_PerkAdditionFramework))
- TweakXL / Codeware: psiberx
