# Techie Crafting Overhaul

사이버펑크 2077 (2.5) 모드. 테크 특전 트리에 분해를 축으로 한 테크 특전 3종을 추가합니다.

[English](README.md)

| 테크 | 특전 | 효과 |
|---|---|---|
| 9  | 테키 실버핸드 (If Johnny Were a Techie...) | 일반 무기를 분해하면 같은 티어의 레시피를 습득 |
| 15 | 빠지게 만들었어야지 (Should've Been Removable) | 개조부품 자유 탈착·교체, 분해 시 개조부품 회수 |
| 20 | 계획된 개조 (Detail Rigging) | 티어 5 이상 신화 무기의 레플리카를 무기 종류당 1회 제작 |

## 요구 사항

| 구성 | 버전 |
|---|---|
| Cyberpunk 2077 | 2.5 이상 |
| [RED4ext](https://github.com/WopsS/RED4ext) | 1.31.0 이상 |
| [redscript](https://github.com/jac3km4/redscript) | 0.5.32 이상 |
| [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) | 2.5 호환 최신 |
| [Codeware](https://github.com/psiberx/cp2077-codeware) | 2.5 호환 최신 |
| [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) | 1.0.1 이상 |

Perk Addition Framework 가 있어야 특전이 테크 트리의 노드로 나타납니다. 없으면 테크 능력치에 따라 활성화됩니다.
설정은 YAML 파일로 합니다. [Mod Settings](https://github.com/jackhumbert/mod_settings) 가 설치되어 있으면 인게임 설정 메뉴에서도 바꿀 수 있습니다(선택 사항). ArchiveXL 은 사용하지 않습니다.

## 설치

1. 수동 설치
`r6` 폴더를 게임 폴더에 복사합니다.

```
Cyberpunk 2077/
  r6/scripts/TechieCraftingOverhaul/*.reds
  r6/tweaks/TechieCraftingOverhaul/*.yaml
```

2. 모드 매니저를 통한 설치(권장)
다운로드 한 zip 파일을 그대로 모드 매니저를 통해 설치하세요.

제거 시: 이 모드로 습득한 레시피(티어 레시피, 레플리카 레시피)는 세이브에 저장됩니다. 모드를 지우면 제작 메뉴가 해당 항목을 찾지 못합니다. 다른 레시피 추가 모드와 같은 제약입니다.

## 특전 트리 배치

| 특전 | 티어 | 선행 |
|---|---|---|
| 테키 실버핸드 | 프로 (9) | 없음 |
| 빠지게 만들었어야지 | 천재 (15) | 테키 실버핸드 |
| 계획된 개조 | 전설 (20) | 빠지게 만들었어야지 |

세 노드는 테크 트리 2행 우측 영역에 사슬로 이어지며, 바닐라 레이아웃에 정의된 연결 쌍을 사용합니다. 15/20 특전은 2행 영역에 놓이지만 티어 레코드에 따라 테크 15/20 에서 해제됩니다.

`perkMode: attribute`(또는 프레임워크 미설치) 에서는 테크 능력치가 9 / 15 / 20 에 도달하면 특전이 활성화됩니다.

## 특전 상세

### 테키 실버핸드 (테크 9)

- 일반 무기(신화 무기·레플리카·퀘스트 아이템 제외)를 분해하면 그 무기 모델의 레시피가 분해한 무기와 같은 티어로 제작 목록에 추가됩니다(티어 2 무기 → 티어 2 레시피).
- 외형 변형(핌프·네온·밀리터리)을 분해해도 기본 외형 레시피를 습득합니다.
- 제작 비용은 바닐라 값을 그대로 따릅니다. 티어 1~5(플러스 포함)는 같은 등급의 바닐라 레시피 비용(해당 티어 부품 30개)을 그대로 씁니다. 티어 5+는 신화 무기의 강화 비용(티어 5 부품 75개)을 더하고, 티어 5++는 거기에 5+ → 5++ 강화 비용(티어 5 부품 200개)을 더합니다.

  | 티어 | 비용 |
  |---|---|
  | 1, 1+ … 4, 4+ | 해당 티어 부품 30개 |
  | 5 | 티어 5 부품 30개 |
  | 5+ | 티어 5 부품 105개 |
  | 5++ | 티어 5 부품 305개 |
- 같은 이름·같은 등급의 일반 무기 레시피를 이미 알고 있으면 그 티어는 습득하지 않습니다.
- 제작되는 무기는 랜덤 조준경/개조부품 슬롯이 제거된 기본 외형입니다.

### 빠지게 만들었어야지 (테크 15)

- 탈착: 모든 무기에서 개조부품 해제를 허용합니다. 해제된 부품은 바닐라 경로로 인벤토리에 돌아옵니다.
- 교체: 바닐라는 교체된 부품을 파괴합니다. 특전 활성 시 같은 부품 1개를 돌려줍니다.
- 분해: 분해 결과에 장착된 개조부품·조준경·총구를 추가합니다.
- 계획된 개조에서 소모되는 기반 무기도 같은 회수 로직을 거칩니다.

### 계획된 개조 (테크 20)

- 모든 신화 무기에 레플리카 레시피가 준비됩니다. 레플리카는 퀘스트 아이템 표시와 습득 시 퀘스트 반응이 제거된 사본이며, 모드 무기도 포함됩니다. 스키피(음성·모드 전환·퀘스트 회수)와 에레부스(블랙월 연출)처럼 퀘스트 연출이 원본 아이템에 묶인 무기, 그리고 퀘스트 전용 대역(저격 둥지의 라세츠)은 기본 제외 목록에 있습니다(`replicaExcluded`).
- 제작 메뉴를 열었을 때 인벤토리의 티어 5 이상 원본 신화 무기를 보유할 경우, 레플리카 레시피가 목록에 표시됩니다(특전 활성, 아직 복제하지 않은 종류). 원본이 인벤토리에서 빠지거나 그 종류를 복제하면 숨겨집니다.
- 제작 조건(모두 충족): 특전 활성 / 원본 소지(티어 5+) / 매핑이 있는 무기는 기반 무기 소지(티어 5+, 매핑 항목 수만큼, 장착 중·퀘스트 아이템 제외) / 설정된 부품 수량 / 아직 복제하지 않은 무기 종류 / 원본이 레플리카가 아님. 기반 무기 매핑이 전혀 없는 신화 무기는 부품만 소모합니다.
- 기반 무기는 무기 종류와 표시 이름이 같고 신화 무기가 아니면 인정됩니다.
- 무기 재료가 둘 이상이거나 같은 무기를 여러 개 요구하는 레시피는 두 번째 무기부터(또는 개수가 필요한 무기는) 일반 재료 줄에 개수와 함께 표시됩니다.
- 비용은 프리셋(`replicaPreset`)으로 정합니다.

  | 프리셋 | 비용 |
  |---|---|
  | `base` (기본) | 기반 무기 + 티어 5 부품 200개 |
  | `parts` | 티어 5 부품 200개 (기반 무기 없음) |
  | `fusion` | 같은 원본 신화 무기 2개 추가 소모 (원본 1개는 유지, 부품 없음) |
  | `custom` | 설정의 개별 값(기반 무기 사용 여부, 원본 추가 소모 수, 부품 수량) |
- 원본은 유지, 기반 무기 소모(분해 판정, 개조부품 회수) 후 레플리카를 지급합니다. 레플리카의 업그레이드 횟수·등급·플러스 스탯·고유 효과는 원본과 동일합니다.
- 복제 기록(무기 종류당 1회)은 세이브에 저장되며 레플리카를 분해해도 초기화되지 않습니다.
- 레플리카는 다른 신화 무기처럼 기본적으로 분해할 수 없습니다. `replicaDisassembleAllowed: true` 로 바꾸면 레플리카만 예외로 분해할 수 있습니다.

### 기반 무기 매핑 (`TCO_BaseWeaponMap.yaml`)

- 2.5 tweak 소스에서 생성한 바닐라 신화 119개 항목. 대부분 부모 프리셋(`Preset_<무기>_Default`)이며, 수동 지정이 가능합니다. 무기를 둘 이상 적으면 전부 필요하고, 같은 무기를 두 번 적으면 2개가 필요합니다.
- 목록에 없는 신화 무기(모드 무기)는 같은 무기 종류 + 같은 `friendlyName` 의 `_Default` 프리셋으로 자동 매칭합니다.
- 형식:
  ```yaml
  TCO.BaseMap.Items.Preset_Silverhand_3516:
    $type: Craftable
    craftableItem: [ Items.Preset_Overture_Default ]
  ```
- 무기별 비용 재정의: `TCO.ReplicaCost.<신화 무기 레코드>` 이름의 CraftingPackage 를 정의하면 그 무기는 프리셋 대신 이 레시피를 씁니다. 무기 재료는 기반 무기로(신화 무기 자체도 가능), 나머지는 부품으로 소모됩니다. 예시는 `TCO_BaseWeaponMap.yaml` 끝에 있습니다.

## 설정 (`TCO_Config.yaml`)

Mod Settings 가 설치되어 있으면 아래 표에서 '메뉴' 칸에 ✓ 가 있는 항목은 인게임 설정 메뉴(Mod Settings → Techie Crafting Overhaul)의 값이 쓰이고, YAML 의 같은 항목은 무시됩니다. 메뉴에서 바꾼 값은 게임을 다시 켜지 않아도 바로 적용됩니다. ✓ 가 없는 항목과 기반 무기 매핑, 무기별 비용 재정의는 YAML 에서만 설정합니다. Mod Settings 가 없으면 전부 YAML 을 읽습니다.

| 키 | 기본값 | 메뉴 | 설명 |
|---|---|---|---|
| `perkMode` | auto | | `auto`: Perk Addition Framework 가 있으면 트리 노드를 사용, 없으면 능력치에 따라 자동으로 지정됩니다. `tree` / `attribute` 로 고정 가능 |
| `perk9Enabled` / `perk15Enabled` / `perk20Enabled` | true | ✓ | 특전별 on/off |
| `perk9Attribute` / `perk15Attribute` / `perk20Attribute` | 9 / 15 / 20 | ✓ | attribute 모드에서 요구하는 테크 능력치(tree 모드는 바닐라 티어 9/15/20) |
| `replicaPreset` | base | ✓ | 레플리카 비용 프리셋: `base` / `parts` / `fusion` / `custom` |
| `replicaUseBaseWeapon` / `replicaOriginalCopies` | true / 0 | ✓ | `custom` 프리셋의 기반 무기 사용 여부, 원본 추가 소모 수 |
| `replicaMaterialItem` | `Items.LegendaryMaterial1` | | 복제에 소모되는 부품 |
| `replicaMaterialAmount` | 200 | ✓ | 부품 수량 (`base` / `parts` / `custom`) |
| `replicaRequiredTier` | 8 | ✓ | 원본·기반 무기의 최소 EffectiveTier (8 = 티어 5, 9 = 5+, 10 = 5++) |
| `replicaDisassembleAllowed` | false | ✓ | 레플리카 분해 허용 |
| `replicaExcluded` | 스키피, 에레부스, 저격 둥지 라세츠 | | 레플리카를 만들지 않을 신화 무기 목록 |
| `recipeTierMode` | equal | ✓ | 9 특전 습득 범위: `equal` 같은 티어 / `upto` 이하 전부 / `all` 전부 |
| `notifications` | true | ✓ | 화면 알림 |
| `debugLog` | false | ✓ | 디버그 메시지. 레시피를 건너뛴 이유와 제작 메뉴를 열 때의 레플리카 목록 검사 결과를 화면 알림으로 표시 |

## 파일 구성

```
r6/scripts/TechieCraftingOverhaul/
  TCO_Core.reds            설정 읽기, 문자열(한/영), 헬퍼, ScriptableSystem(특전 판정, 복제 기록)
  TCO_Localization.reds    Codeware 현지화: 특전 이름/설명, 설정 메뉴 라벨 (한/영)
  TCO_Tweaks.reds          TweakXL ScriptableTweak: 티어 레시피, 레플리카 레시피, 특전 노드 연결
  TCO_Perk9_Recipes.reds   분해 후킹 → 레시피 습득
  TCO_Perk15_Mods.reds     탈착 판정, 교체 보존, UI 차단 해제, 분해 시 회수
  TCO_Perk20_Replica.reds  레플리카 레시피 동기화, 조건 검사, 레플리카 제작 흐름
  TCO_UI.reds              레플리카 이름 접미사, 제작 화면의 기반 무기 표시
  TCO_Settings.reds        Mod Settings 연동(선택): 인게임 설정 메뉴 항목
r6/tweaks/TechieCraftingOverhaul/
  TCO_Config.yaml          설정
  TCO_BaseWeaponMap.yaml   신화 무기 → 기반 무기 (바닐라 전체)
  TCO_ModelMap.yaml        9 특전 모델/외형 예외
  TCO_Perks.yaml           테크 트리 특전 노드 3종 (NewPerks.TCO_Tech_*)
  TCO_Icons.yaml           특전 아이콘 재지정 (커스텀 아틀라스 템플릿, 주석 처리)
```

## 제약

- 특전 노드는 Perk Addition Framework 에 의존합니다. 같은 슬롯을 쓰는 다른 특전 추가 모드와 충돌합니다(프레임워크 로그에 중복 슬롯 경고).
- 15/20 특전은 트리 2행 영역에 놓입니다. 해제 요구치는 위치와 무관하게 15/20 입니다.
- 바닐라 2.5 는 신화 무기의 분해를 막습니다. 따라서 신화 무기는 9 특전의 습득 대상이 되지 않으며, 레플리카만 예외입니다.
- 무기의 내부 이름을 읽을 수 없는 환경에서는 기본 외형 판정을 외형 태그로 대신합니다.
- 제작 UI 는 기반 무기를 "×1" 로만 표시하고 티어 조건은 표시하지 않습니다. 조건은 버튼 활성 여부와 알림으로 전달됩니다.

## 출처

- 게임 스크립트·tweak 소스: CDPR REDmod 소스 (CDPR-Modding-Documentation/Cyberpunk-Scripts, Cyberpunk-Tweaks, v2.5)
- 특전 enum 확장: [Perk Addition Framework](https://www.nexusmods.com/cyberpunk2077/mods/22758) (JonnesTT, [GitHub](https://github.com/JonnesTT/Cyberpunk_PerkAdditionFramework))
- TweakXL / Codeware: psiberx

## 라이선스

CC0 1.0 (퍼블릭 도메인). 출처 표기 없이 자유롭게 사용·수정·재배포할 수 있습니다. 전문은 [LICENSE](LICENSE) 에 있습니다.
