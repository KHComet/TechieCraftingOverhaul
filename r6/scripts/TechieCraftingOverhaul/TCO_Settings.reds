// ============================================================================
// TCO - Mod Settings 연동 (선택)
//   Mod Settings (jackhumbert/mod_settings) 가 설치되어 있으면 아래 값들을 인게임 설정 메뉴에서 바꿀 수 있고,
//   그 값이 TCO_Config.yaml 의 같은 항목보다 우선한다. 설치되어 있지 않으면 이 클래스는 쓰이지 않고 YAML 을 읽는다.
//
//   동작 방식 (Mod Settings 소스 기준):
//     - 스크립트 로딩 시 "ModSettings.mod" 런타임 프로퍼티가 붙은 필드를 수집해 메뉴 항목으로 만들고,
//       저장된 값(red4ext/plugins/mod_settings/user.ini)을 클래스 기본값에 써 넣는다.
//     - 값이 바뀌면 클래스 기본값과, RegisterListenerToClass 로 등록한 인스턴스의 필드를 함께 갱신한다.
//     - 이름/설명/분류/열거형 값 라벨은 GetLocalizedTextByKey 로 풀고, 키가 없으면 문자열을 그대로 보여준다.
//       라벨 키는 TCO_Localization.reds (Codeware) 에 한국어/영어로 정의되어 있다.
//
//   YAML 에만 남는 설정: perkMode (트리 구조를 로딩 시 결정), replicaMaterialItem, replicaExcluded,
//   기반 무기 매핑, 무기별 비용 재정의. 목록/레코드 ID 는 메뉴로 표현할 수 없다.
// ============================================================================

enum TCO_RecipeTiers {
  Equal = 0,
  UpTo = 1,
  All = 2
}

enum TCO_ReplicaPreset {
  Base = 0,
  Parts = 1,
  Fusion = 2,
  Custom = 3
}

enum TCO_ReplicaTier {
  Tier5 = 0,
  Tier5Plus = 1,
  Tier5PlusPlus = 2
}

public class TCO_Settings {
  // --- 특전 ---------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk9Enabled")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkEnabled-Desc")
  public let perk9Enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk15Enabled")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkEnabled-Desc")
  public let perk15Enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk20Enabled")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkEnabled-Desc")
  public let perk20Enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-PerkFreeUnlock")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkFreeUnlock-Desc")
  public let perkFreeUnlock: Bool = false;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk9Attribute")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkAttribute-Desc")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "3")
  @runtimeProperty("ModSettings.max", "20")
  public let perk9Attribute: Int32 = 9;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk15Attribute")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkAttribute-Desc")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "3")
  @runtimeProperty("ModSettings.max", "20")
  public let perk15Attribute: Int32 = 15;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Perks")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Perk20Attribute")
  @runtimeProperty("ModSettings.description", "TCO-Settings-PerkAttribute-Desc")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "3")
  @runtimeProperty("ModSettings.max", "20")
  public let perk20Attribute: Int32 = 20;

  // --- 9 특전: 레시피 ------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Recipes")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-RecipeTiers")
  @runtimeProperty("ModSettings.description", "TCO-Settings-RecipeTiers-Desc")
  @runtimeProperty("ModSettings.displayValues.Equal", "TCO-Settings-RecipeTiers-Equal")
  @runtimeProperty("ModSettings.displayValues.UpTo", "TCO-Settings-RecipeTiers-UpTo")
  @runtimeProperty("ModSettings.displayValues.All", "TCO-Settings-RecipeTiers-All")
  public let recipeTiers: TCO_RecipeTiers = TCO_RecipeTiers.Equal;

  // --- 20 특전: 레플리카 ---------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaPreset")
  @runtimeProperty("ModSettings.description", "TCO-Settings-ReplicaPreset-Desc")
  @runtimeProperty("ModSettings.displayValues.Base", "TCO-Settings-Preset-Base")
  @runtimeProperty("ModSettings.displayValues.Parts", "TCO-Settings-Preset-Parts")
  @runtimeProperty("ModSettings.displayValues.Fusion", "TCO-Settings-Preset-Fusion")
  @runtimeProperty("ModSettings.displayValues.Custom", "TCO-Settings-Preset-Custom")
  public let replicaPreset: TCO_ReplicaPreset = TCO_ReplicaPreset.Base;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaMaterialAmount")
  @runtimeProperty("ModSettings.description", "TCO-Settings-ReplicaMaterialAmount-Desc")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "1000")
  public let replicaMaterialAmount: Int32 = 200;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaUseBaseWeapon")
  @runtimeProperty("ModSettings.description", "TCO-Settings-CustomOnly-Desc")
  public let replicaUseBaseWeapon: Bool = true;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaOriginalCopies")
  @runtimeProperty("ModSettings.description", "TCO-Settings-CustomOnly-Desc")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "5")
  public let replicaOriginalCopies: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaRequiredTier")
  @runtimeProperty("ModSettings.description", "TCO-Settings-ReplicaRequiredTier-Desc")
  @runtimeProperty("ModSettings.displayValues.Tier5", "TCO-Settings-Tier-5")
  @runtimeProperty("ModSettings.displayValues.Tier5Plus", "TCO-Settings-Tier-5Plus")
  @runtimeProperty("ModSettings.displayValues.Tier5PlusPlus", "TCO-Settings-Tier-5PlusPlus")
  public let replicaRequiredTier: TCO_ReplicaTier = TCO_ReplicaTier.Tier5;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Replica")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-ReplicaDisassemble")
  @runtimeProperty("ModSettings.description", "TCO-Settings-ReplicaDisassemble-Desc")
  public let replicaDisassembleAllowed: Bool = false;

  // --- 기타 ---------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Misc")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-Notifications")
  @runtimeProperty("ModSettings.description", "TCO-Settings-Notifications-Desc")
  public let notifications: Bool = true;

  @runtimeProperty("ModSettings.mod", "Techie Crafting Overhaul")
  @runtimeProperty("ModSettings.category", "TCO-Settings-Cat-Misc")
  @runtimeProperty("ModSettings.displayName", "TCO-Settings-DebugLog")
  @runtimeProperty("ModSettings.description", "TCO-Settings-DebugLog-Desc")
  public let debugLog: Bool = false;

  // Mod Settings 가 변경된 값을 적용한 뒤 호출한다 (RegisterListenerToModifications 로 등록한 객체의 이 이름의 함수).
  // 자동 해금 옵션이 바뀌었을 수 있으므로 지급/회수를 다시 맞춘다. 세션이 없으면(메인 메뉴) 아무 일도 하지 않는다.
  public func OnModSettingsChange() -> Void {
    let sys = TechieCraftingOverhaul.GetInstance(GetGameInstance());
    if IsDefined(sys) {
      sys.SyncFreePerks();
    }
  }
}

// ---------------------------------------------------------------------------
// 조건부 컴파일: Mod Settings 의 redscript 모듈(ModSettingsModule)이 있을 때만 그 API 를 참조한다.
// ---------------------------------------------------------------------------

// 현재 적용 중인 인게임 설정. Mod Settings 가 없으면 null (호출한 쪽이 YAML 을 읽는다).
// 주의: 게임 인스턴스를 쓰므로 TweakDB 생성 단계(TCO_Tweaks.reds)에서는 호출하지 않는다.
@if(ModuleExists("ModSettingsModule"))
public static func TCO_ActiveSettings() -> ref<TCO_Settings> {
  let sys = TechieCraftingOverhaul.GetInstance(GetGameInstance());
  if IsDefined(sys) {
    return sys.GetSettings();
  }
  return new TCO_Settings();
}

@if(!ModuleExists("ModSettingsModule"))
public static func TCO_ActiveSettings() -> ref<TCO_Settings> {
  return null;
}

// 값이 바뀔 때 인스턴스 필드가 함께 갱신되고(ToClass) 변경 알림 OnModSettingsChange 를 받도록(ToModifications) 등록한다.
// Mod Settings 는 둘 다 약한 참조로 들고 있는다.
@if(ModuleExists("ModSettingsModule"))
public static func TCO_RegisterSettingsListener(settings: ref<TCO_Settings>) -> Void {
  ModSettings.RegisterListenerToClass(settings);
  ModSettings.RegisterListenerToModifications(settings);
}

@if(!ModuleExists("ModSettingsModule"))
public static func TCO_RegisterSettingsListener(settings: ref<TCO_Settings>) -> Void {}
