# Techie Crafting Overhaul

사이버펑크 2077 (2.5) 모드. 테크 특전 트리에 분해를 축으로 한 테크 특전 3종을 추가합니다.

[English](README.md)

| 테크 | 특전 | 효과 |
|---|---|---|
| 9  | 테키 실버핸드 (If Johnny Were a Techie...) | 일반 무기를 분해하면 같은 티어의 레시피를 습득 |
| 15 | 빠지게 만들었어야지 (Should've Been Removable) | 개조부품 자유 탈착·교체, 분해 시 개조부품 회수 |
| 20 | 계획된 개조 (Detail Rigging) | 티어 5 이상 아이코닉 무기의 레플리카를 무기 종류당 1회 제작 |

## 요구 사항

| 구성 | 버전 |
|---|---|
| Cyberpunk 2077 | 2.5 이상 |
| [RED4ext](https://github.com/WopsS/RED4ext) | 1.31.0 이상 |
| [redscript](https://github.com/jac3km4/redscript) | 0.5.32 이상 |
| [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) | 2.5 호환 최신 |
| [Codeware](https://github.com/psiberx/cp2077-codeware) | 2.5 호환 최신 |
| [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) | 1.0.1 이상 |

Perk Addition Framework 가 있어야 특전이 테크 트리의 노드로 나타납니다. 없으면 능력치 임계값 모드로 동작합니다(`perkMode` 참조).
ArchiveXL, Mod Settings 는 사용하지 않습니다. 설정은 YAML 파일로 합니다.

## 설치

`r6` 폴더를 게임 폴더에 복사합니다.

```
Cyberpunk 2077/
  r6/scripts/TechieCraftingOverhaul/*.reds
  r6/tweaks/TechieCraftingOverhaul/*.yaml
```

제거 시: 이 모드로 습득한 레시피(티어 레시피, 레플리카 레시피)는 세이브에 레코드 ID 로 저장됩니다. 모드를 지우면 제작 메뉴가 해당 항목을 찾지 못합니다. 다른 레시피 추가 모드와 같은 제약입니다.

## 특전 트리 배치

| 특전 | 슬롯 | 티어 | 선행 |
|---|---|---|---|
| 테키 실버핸드 | `Right_Milestone_2` (2행 우측, 마일스톤 위젯) | Adept (9) | 없음 |
| 빠지게 만들었어야지 | `Right_Perk_2_1` (2행 우측) | Expert (15) | 9 특전 |
| 계획된 개조 | `Right_Perk_2_3` (2행 우측) | Master (20) | 15 특전 |

세 노드는 테크 트리 2행 우측 영역에 사슬로 이어지며, 바닐라 레이아웃에 정의된 연결 쌍을 사용합니다. 15/20 특전은 2행 영역에 놓이지만 티어 레코드에 따라 테크 15/20 에서 해제됩니다. 설명문에 요구 능력치가 적혀 있습니다.

구매에는 바닐라 특전 포인트가 들며, 속성 초기화 시 환불은 Perk Addition Framework 가 처리합니다.

`perkMode: attribute`(또는 프레임워크 미설치) 에서는 테크 능력치가 `perk9Attribute` / `perk15Attribute` / `perk20Attribute` 값에 도달하면 특전이 활성화됩니다.

## 특전 상세

### 테키 실버핸드 (테크 9)

- 일반 무기(아이코닉·레플리카·퀘스트 아이템 제외)를 분해하면 그 무기 모델의 레시피가 분해한 무기와 같은 티어로 제작 목록에 추가됩니다(티어 2 무기 → 티어 2 레시피).
- 모델당 11개 티어 레코드(1, 1+, 2, 2+, … 5, 5+, 5++)를 로딩 시 생성합니다. `recipeTierMode` 로 `equal`(같은 티어, 기본) / `upto`(이하 전부) / `all`(전부) 을 선택합니다.
- 모델 결정 순서: `_Default` 프리셋 → `TCO_ModelMap.yaml` 항목 → 같은 표시 이름의 `_Default` 프리셋 → 분해한 프리셋 자체. 외형 변형을 분해해도 기본 외형 레시피를 습득합니다.
- 제작 비용은 로딩 시 바닐라 레코드에서 읽습니다. 티어 1~5(플러스 포함)는 같은 등급의 바닐라 레시피 비용(`Items.Small_<등급>_Crafting_Materials_Weapon`, 부품 30개)을 그대로 씁니다. 티어 5+는 아이코닉의 5 → 5+ 강화 비용(`Upgrading.Legendary`, 티어 5 부품 75개)을 더하고, 티어 5++는 거기에 5+ → 5++ 강화 비용(`Upgrading.LegendaryPlus`, 티어 5 부품 200개)을 더합니다.

  | 티어 | 비용 |
  |---|---|
  | 1, 1+ … 4, 4+ | 해당 티어 부품 30개 |
  | 5 | 티어 5 부품 30개 |
  | 5+ | 티어 5 부품 105개 |
  | 5++ | 티어 5 부품 305개 |
- 같은 이름·같은 등급의 일반 무기 레시피(상점 레시피 `Items.Craftable_*`, 다른 모드)가 이미 있으면 그 티어는 건너뜁니다.
- 제작되는 무기는 바닐라 `Craftable_*` 과 같이 랜덤 조준경/개조부품 슬롯이 제거된 기본 외형입니다.

### 빠지게 만들었어야지 (테크 15)

- 탈착: `RPGManager.CanPartBeUnequipped` 가 아이코닉뿐 아니라 모든 무기에서 개조부품 해제를 허용합니다. 해제된 부품은 바닐라 `RemoveItemPart` 경로로 인벤토리에 돌아옵니다.
- 교체: 바닐라 `ItemModificationSystem.InstallItemPart` 는 교체된 부품을 파괴합니다. 특전 활성 시 같은 레코드의 부품 1개를 돌려줍니다. 인벤토리 UI 의 "빈 슬롯 없음" 차단(일반 무기)과 파괴 경고 팝업(아이코닉)을 건너뜁니다.
- 분해: `GetDisassemblyResultItems` 결과에 장착된 개조부품·조준경·총구를 추가합니다. `DummyPart` 와 본체 부품은 제외합니다.
- 계획된 개조에서 소모되는 기반 무기도 같은 회수 로직을 거칩니다.

### 계획된 개조 (테크 20)

- 로딩 시 모든 아이코닉 무기 레코드마다 레플리카 레코드 `<아이코닉>_TCO_Replica` 를 생성합니다(`Quest` 태그 제거, `OnLooted` 퀘스트 팩트 효과 제거, `TCO_Replica` 태그 추가). 모드 무기도 포함됩니다.
- 제작 메뉴를 열면 인벤토리의 티어 5 이상 원본 아이코닉마다 레플리카 레시피가 목록에 표시됩니다(특전 활성, 아직 복제하지 않은 종류). 재료는 표시 조건이 아닙니다. 원본이 인벤토리에서 빠지거나 그 종류를 복제하면 숨겨집니다.
- 제작 조건(모두 충족): 특전 활성 / 원본 소지(티어 5+) / 매핑이 있는 무기는 기반 무기 소지(티어 5+, 매핑 항목 수만큼, 장착 중·퀘스트 아이템 제외) / 설정된 부품 수량 / 아직 복제하지 않은 무기 종류 / 원본이 레플리카가 아님. 기반 무기 매핑이 전혀 없는 아이코닉은 부품만 소모합니다.
- 결과: 원본 유지, 기반 무기 소모(분해 판정, 개조부품 회수), 레플리카 지급. 레플리카의 업그레이드 횟수·등급·플러스 스탯을 원본과 맞춰 같은 티어가 됩니다. 고유 효과는 레코드 복제로 따라옵니다.
- 1회 기준은 무기 종류(표시 이름 LocKey)입니다. 기록은 세이브에 저장되며 레플리카를 분해해도 초기화되지 않습니다.
- 레플리카는 아이코닉 태그가 있어도 분해할 수 있습니다(`replicaDisassembleAllowed`).

### 기반 무기 매핑 (`TCO_BaseWeaponMap.yaml`)

- 2.5 tweak 소스에서 생성한 바닐라 아이코닉 119개 항목. 대부분 부모 프리셋(`Preset_<무기>_Default`)이며, 대응 계열이 없는 12개는 수동 지정(말로리안 암즈 3516 → 타마유라 `Preset_Kenshin_Default` + 오버추어, 케어테이커의 삽 → 해머, 코튼마우스 / 서 존 / 팅커벨 → 바톤 등).
- 아이코닉의 등급 변형 레코드(`Common_` / `Uncommon_` / `Rare_` / `Epic_` / `Legendary_<아이코닉>`, 2.x 에서 플레이어가 실제로 소지하는 레코드)는 표시 이름이 같은 `Preset_<아이코닉>` 의 매핑을 물려받습니다.
- 테이블에 없는 아이코닉(모드 무기)은 같은 무기 종류 + 같은 `friendlyName` 의 `_Default` 프리셋으로 자동 매칭합니다.
- 형식:
  ```yaml
  TCO.BaseMap.Items.Preset_Silverhand_3516:
    $type: Craftable
    craftableItem: [ Items.Preset_Kenshin_Default, Items.Preset_Overture_Default ]
  ```

## 설정 (`TCO_Config.yaml`)

| 키 | 기본값 | 설명 |
|---|---|---|
| `perkMode` | auto | `auto`: Perk Addition Framework 가 있으면 트리 노드, 없으면 능력치 임계값. `tree` / `attribute` 로 고정 가능 |
| `perk9Enabled` / `perk15Enabled` / `perk20Enabled` | true | 특전별 on/off |
| `perk9Attribute` / `perk15Attribute` / `perk20Attribute` | 9 / 15 / 20 | attribute 모드에서 요구하는 테크 능력치(tree 모드는 바닐라 티어 9/15/20) |
| `replicaMaterialItem` | `Items.LegendaryMaterial1` | 복제에 소모되는 부품 |
| `replicaMaterialAmount` | 200 | 부품 수량 |
| `replicaRequiredTier` | 8 | 원본·기반 무기의 최소 EffectiveTier (8 = 티어 5, 9 = 5+, 10 = 5++) |
| `replicaDisassembleAllowed` | true | 레플리카 분해 허용 |
| `recipeTierMode` | equal | 9 특전 습득 범위: `equal` 같은 티어 / `upto` 이하 전부 / `all` 전부 |
| `notifications` | true | 화면 알림 |
| `debugLog` | false | `[TCO]` 디버그 로그 (`FTLog` 와 `ModLog(n"TechieCraftingOverhaul")` 로 출력). 제작 메뉴를 열 때 레플리카 목록 동기화 요약을 화면 알림으로도 표시 |

## 커스텀 특전 아이콘

특전 아이콘은 `NewPerk.perkIcon` 이 가리키는 `UIIcon` 레코드(`atlasResourcePath` + `atlasPartName`)로 정해집니다. 기본값은 바닐라 아이콘입니다.

1. 흰색 실루엣 + 투명 배경의 정사각형 PNG 를 준비합니다(색은 게임이 상태별로 입힙니다). 파일 이름 = 아틀라스 조각 이름.
2. WolvenKit 로 PNG 를 `.inkatlas` + `.xbm` 으로 만들고(예: `mod\tco\tco_perk_icons.inkatlas`) `archive/pc/mod/` 로 팩합니다. ArchiveXL 은 필요 없습니다.
3. `TCO_Icons.yaml` 의 `UIIcon.TCO_Perk*` 레코드와 `perkIcon` 재지정 줄의 주석을 풀고 경로와 조각 이름을 맞춥니다.

아이콘만 바뀝니다. 노드의 모양과 크기는 슬롯 위젯이 정합니다.

## 파일 구성

```
r6/scripts/TechieCraftingOverhaul/
  TCO_Core.reds            설정 읽기, 문자열(한/영), 헬퍼, ScriptableSystem(특전 판정, 복제 기록)
  TCO_Localization.reds    Codeware 현지화: 특전 이름/설명 (한/영)
  TCO_Tweaks.reds          TweakXL ScriptableTweak: 티어 레시피 레코드, 레플리카 레코드, 특전 노드 연결
  TCO_Perk9_Recipes.reds   분해 후킹 → 레시피 습득
  TCO_Perk15_Mods.reds     탈착 판정, 교체 보존, UI 차단 해제, 분해 시 회수
  TCO_Perk20_Replica.reds  레플리카 레시피 동기화, 조건 검사, 레플리카 제작 흐름
  TCO_UI.reds              레플리카 이름 접미사
r6/tweaks/TechieCraftingOverhaul/
  TCO_Config.yaml          설정
  TCO_BaseWeaponMap.yaml   아이코닉 → 기반 무기 (바닐라 전체)
  TCO_ModelMap.yaml        9 특전 모델/외형 예외
  TCO_Perks.yaml           테크 트리 특전 노드 3종 (NewPerks.TCO_Tech_*)
  TCO_Icons.yaml           특전 아이콘 재지정 (커스텀 아틀라스 템플릿, 주석 처리)
```

## 제약

- 특전 노드는 Perk Addition Framework 에 의존합니다. 같은 슬롯을 쓰는 다른 특전 추가 모드와 충돌합니다(프레임워크 로그에 중복 슬롯 경고).
- 15/20 특전은 트리 2행 영역에 놓입니다. 해제 요구치는 위치와 무관하게 15/20 입니다.
- 커스텀 아틀라스를 넣지 않으면 바닐라 테크 아이콘을 재사용합니다.
- 2.5 의 `CraftingSystem.CanItemBeDisassembled` 는 `IconicWeapon` 아이템의 분해를 막습니다. 따라서 아이코닉은 9 특전의 습득 대상이 되지 않으며, 레플리카만 예외입니다.
- 레코드 이름(`TDBID.ToStringDEBUG`)을 읽을 수 없는 환경에서는 `_Default` 판정을 `visualTags == ["Default"]` 로 대신합니다.
- 제작 UI 는 기반 무기를 "×1" 로만 표시하고 티어 조건은 표시하지 않습니다. 조건은 버튼 활성 여부와 알림으로 전달됩니다.

## 출처

- 게임 스크립트·tweak 소스: CDPR REDmod 소스 (CDPR-Modding-Documentation/Cyberpunk-Scripts, Cyberpunk-Tweaks, v2.5)
- 특전 enum 확장: [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) (JonnesTT, [GitHub](https://github.com/JonnesTT/Cyberpunk_PerkAdditionFramework))
- TweakXL / Codeware: psiberx
