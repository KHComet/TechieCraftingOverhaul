// ============================================================================
// Techie Crafting Overhaul (TCO) - Core
//   Cyberpunk 2077 2.5+ / redscript 0.5.32+ / TweakXL 1.x
//
//   세 특전을 하나의 ScriptableSystem 으로 관리한다.
//     9  "If Johnny Were a Techie..."  : 일반 무기 분해 -> 모델 레시피 습득
//     15 "Should've Been Removable"    : 개조부품 자유 탈착 + 분해 시 회수
//     20 "Detail Rigging"              : 티어5+ 아이코닉 1회 복제
//
//   특전 판정은 두 모드가 있다 (TCO.Config.perkMode):
//     tree      : Perk Addition Framework(Codeware 리플렉션으로 gamedataNewPerkType 확장) 가
//                 TCO_Perks.yaml 의 NewPerks.TCO_Tech_* 레코드를 실제 특전으로 만든 경우,
//                 PlayerDevelopmentData.IsNewPerkBought 로 구매 여부를 본다.
//     attribute : 테크 능력치 투자 포인트(9/15/20)로 판정한다 (프레임워크가 없을 때의 대체 경로).
// ============================================================================

enum TCO_Perk {
  Techie9 = 0,
  Removable15 = 1,
  Rigging20 = 2
}

// ---------------------------------------------------------------------------
// 설정
//   Mod Settings 가 설치되어 있으면 인게임 설정 값(TCO_Settings)을, 없으면 TCO_Config.yaml 의 flat 을 읽는다.
//   YAML 전용: perkMode, replicaMaterialItem, replicaExcluded. 이 셋과 Yaml* 접근자만 TweakDB 생성 단계에서 쓸 수 있다.
// ---------------------------------------------------------------------------
public abstract class TCO_Config {
  // --- YAML 전용 (로딩 시 결정되는 구조 / 레코드 ID / 목록) ---
  public static func PerkMode() -> CName { return TweakDBInterface.GetCName(t"TCO.Config.perkMode", n"auto"); }
  public static func ReplicaMaterialItem() -> TweakDBID { return TweakDBInterface.GetForeignKey(t"TCO.Config.replicaMaterialItem", t"Items.LegendaryMaterial1"); }
  public static func ReplicaExcluded() -> array<TweakDBID> { return TweakDBInterface.GetForeignKeyArray(t"TCO.Config.replicaExcluded"); }
  public static func YamlReplicaMaterialAmount() -> Int32 { return Max(0, TweakDBInterface.GetInt(t"TCO.Config.replicaMaterialAmount", 200)); }

  // --- 특전 ---
  public static func Perk9Enabled() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk9Enabled; }
    return TweakDBInterface.GetBool(t"TCO.Config.perk9Enabled", true);
  }
  public static func Perk15Enabled() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk15Enabled; }
    return TweakDBInterface.GetBool(t"TCO.Config.perk15Enabled", true);
  }
  public static func Perk20Enabled() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk20Enabled; }
    return TweakDBInterface.GetBool(t"TCO.Config.perk20Enabled", true);
  }
  // 특전 노드를 포인트 없이 자동 해금 (트리 노드가 있을 때만 의미가 있다)
  public static func PerkFreeUnlock() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perkFreeUnlock; }
    return TweakDBInterface.GetBool(t"TCO.Config.perkFreeUnlock", false);
  }
  public static func Perk9Attribute() -> Int32 {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk9Attribute; }
    return TweakDBInterface.GetInt(t"TCO.Config.perk9Attribute", 9);
  }
  public static func Perk15Attribute() -> Int32 {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk15Attribute; }
    return TweakDBInterface.GetInt(t"TCO.Config.perk15Attribute", 15);
  }
  public static func Perk20Attribute() -> Int32 {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.perk20Attribute; }
    return TweakDBInterface.GetInt(t"TCO.Config.perk20Attribute", 20);
  }

  // --- 9 특전 ---
  public static func RecipeTierMode() -> CName {
    let s = TCO_ActiveSettings();
    if IsDefined(s) {
      switch s.recipeTiers {
        case TCO_RecipeTiers.UpTo: return n"upto";
        case TCO_RecipeTiers.All: return n"all";
        default: return n"equal";
      }
    }
    return TweakDBInterface.GetCName(t"TCO.Config.recipeTierMode", n"equal");
  }

  // --- 20 특전 ---
  // 레플리카 비용 프리셋: base(기반 무기 + 부품) / parts(부품만) / fusion(원본 2개 추가 소모, 부품 없음) / custom(개별 값)
  public static func ReplicaPreset() -> CName {
    let s = TCO_ActiveSettings();
    if IsDefined(s) {
      switch s.replicaPreset {
        case TCO_ReplicaPreset.Parts: return n"parts";
        case TCO_ReplicaPreset.Fusion: return n"fusion";
        case TCO_ReplicaPreset.Custom: return n"custom";
        default: return n"base";
      }
    }
    return TweakDBInterface.GetCName(t"TCO.Config.replicaPreset", n"base");
  }
  public static func ReplicaUseBaseWeapon() -> Bool {
    let preset = TCO_Config.ReplicaPreset();
    if Equals(preset, n"parts") || Equals(preset, n"fusion") { return false; }
    if Equals(preset, n"custom") {
      let s = TCO_ActiveSettings();
      if IsDefined(s) { return s.replicaUseBaseWeapon; }
      return TweakDBInterface.GetBool(t"TCO.Config.replicaUseBaseWeapon", true);
    }
    return true;
  }
  public static func ReplicaOriginalCopies() -> Int32 {
    let preset = TCO_Config.ReplicaPreset();
    if Equals(preset, n"fusion") { return 2; }
    if Equals(preset, n"custom") {
      let s = TCO_ActiveSettings();
      if IsDefined(s) { return Max(0, s.replicaOriginalCopies); }
      return Max(0, TweakDBInterface.GetInt(t"TCO.Config.replicaOriginalCopies", 0));
    }
    return 0;
  }
  public static func ReplicaMaterialAmount() -> Int32 {
    if Equals(TCO_Config.ReplicaPreset(), n"fusion") { return 0; }
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return Max(0, s.replicaMaterialAmount); }
    return TCO_Config.YamlReplicaMaterialAmount();
  }
  // 원본·기반 무기 최소 EffectiveTier (8 = 티어 5, 9 = 5+, 10 = 5++)
  public static func ReplicaRequiredTier() -> Float {
    let s = TCO_ActiveSettings();
    if IsDefined(s) {
      switch s.replicaRequiredTier {
        case TCO_ReplicaTier.Tier5Plus: return 9.0;
        case TCO_ReplicaTier.Tier5PlusPlus: return 10.0;
        default: return 8.0;
      }
    }
    return Cast<Float>(TweakDBInterface.GetInt(t"TCO.Config.replicaRequiredTier", 8));
  }
  public static func ReplicaDisassembleAllowed() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.replicaDisassembleAllowed; }
    return TweakDBInterface.GetBool(t"TCO.Config.replicaDisassembleAllowed", false);
  }

  // --- 기타 ---
  public static func Notifications() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.notifications; }
    return TweakDBInterface.GetBool(t"TCO.Config.notifications", true);
  }
  public static func DebugLog() -> Bool {
    let s = TCO_ActiveSettings();
    if IsDefined(s) { return s.debugLog; }
    return TweakDBInterface.GetBool(t"TCO.Config.debugLog", false);
  }
}

// ---------------------------------------------------------------------------
// 표시 문자열 (게임 언어 설정에 따라 한국어 / 영어)
// ---------------------------------------------------------------------------
public abstract class TCO_Text {
  public static func Language(gi: GameInstance) -> CName {
    let settings = GameInstance.GetSettingsSystem(gi);
    if !IsDefined(settings) { return n"en-us"; }
    let langVar = settings.GetVar(n"/language", n"OnScreen") as ConfigVarListName;
    if !IsDefined(langVar) { return n"en-us"; }
    return langVar.GetValue();
  }

  public static func IsKorean(gi: GameInstance) -> Bool {
    return Equals(TCO_Text.Language(gi), n"kr-kr");
  }

  public static func TierLabel(tierIndex: Int32) -> String {
    switch tierIndex {
      case 0: return "1";
      case 1: return "1+";
      case 2: return "2";
      case 3: return "2+";
      case 4: return "3";
      case 5: return "3+";
      case 6: return "4";
      case 7: return "4+";
      case 8: return "5";
      case 9: return "5+";
      case 10: return "5++";
      default: return "?";
    }
  }

  public static func RecipeLearned(gi: GameInstance, itemName: String, tierLabels: String) -> String {
    if TCO_Text.IsKorean(gi) {
      return "분해 중 구조를 익혔다 - 새 제작 도안: " + itemName + " (티어 " + tierLabels + ")";
    }
    return "Reverse-engineered while disassembling - new crafting spec: " + itemName + " (Tier " + tierLabels + ")";
  }

  public static func ReplicaSuffix(gi: GameInstance) -> String {
    if TCO_Text.IsKorean(gi) { return " (레플리카)"; }
    return " (Replica)";
  }

  public static func ReplicaCrafted(gi: GameInstance, itemName: String) -> String {
    if TCO_Text.IsKorean(gi) { return "계획된 개조 완료 - 레플리카 제작: " + itemName; }
    return "Detail rigging complete - replica assembled: " + itemName;
  }

  public static func PerkAutoUnlocked(gi: GameInstance, perkName: String) -> String {
    if TCO_Text.IsKorean(gi) { return "특전 자동 해금: " + perkName; }
    return "Perk unlocked: " + perkName;
  }

  public static func ReplicaFailed(gi: GameInstance) -> String {
    if TCO_Text.IsKorean(gi) { return "복제 조건을 충족하지 못했습니다 (원본 티어5+, 기반 무기 티어5+, 부품, 1회 제한)."; }
    return "Replica requirements not met (original T5+, base weapon T5+, components, once per weapon).";
  }
}

// ---------------------------------------------------------------------------
// 공용 헬퍼
// ---------------------------------------------------------------------------
public static func TCO_Log(text: String) -> Void {
  if TCO_Config.DebugLog() {
    FTLog("[TCO] " + text);
    ModLog(n"TechieCraftingOverhaul", text);
  }
}

public static func TCO_Notify(gi: GameInstance, text: String) -> Void {
  if !TCO_Config.Notifications() { return; }
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = 6.0;
  msg.message = text;
  let bb = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Notifications);
  if IsDefined(bb) {
    bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
  }
}

public static func TCO_IsPerkActive(perk: TCO_Perk) -> Bool {
  let sys = TechieCraftingOverhaul.GetInstance(GetGameInstance());
  return IsDefined(sys) && sys.IsPerkActive(perk);
}

// 트리 노드 모드: TCO_Perks.yaml 의 enumName 과 같아야 한다
public static func TCO_PerkEnumName(perk: TCO_Perk) -> CName {
  switch perk {
    case TCO_Perk.Techie9: return n"TCO_Tech_Johnny";
    case TCO_Perk.Removable15: return n"TCO_Tech_Removable";
    case TCO_Perk.Rigging20: return n"TCO_Tech_Rigging";
    default: return n"";
  }
}

// Perk Addition Framework 가 enum 을 확장했으면 실제 특전 타입을 돌려준다.
// 확장되지 않은 이름은 EnumValueFromName 결과가 유효하지 않거나 다른 레코드를 가리키므로
// 레코드의 enumName 까지 대조해 확인한다.
public static func TCO_ResolvePerkType(perk: TCO_Perk, out perkType: gamedataNewPerkType) -> Bool {
  let enumName = TCO_PerkEnumName(perk);
  let value = EnumValueFromName(n"gamedataNewPerkType", enumName);
  if value < 0l { return false; }
  let candidate = IntEnum<gamedataNewPerkType>(value);
  let record = RPGManager.GetNewPerkRecord(candidate);
  if !IsDefined(record) || NotEquals(record.EnumName(), enumName) { return false; }
  perkType = candidate;
  return true;
}

public static func TCO_ItemName(record: wref<Item_Record>) -> String {
  if !IsDefined(record) { return ""; }
  return GetLocalizedItemNameByCName(record.DisplayName());
}

// EffectiveTier 스탯: 0 = 티어1 ... 8 = 티어5, 9 = 티어5+, 10 = 티어5++ (Quality*2 + IsItemPlus)
public static func TCO_GetEffectiveTier(itemData: wref<gameItemData>) -> Float {
  if !IsDefined(itemData) { return 0.0; }
  return itemData.GetStatValueByType(gamedataStatType.EffectiveTier);
}

public static func TCO_IsWeaponItem(itemData: wref<gameItemData>) -> Bool {
  return IsDefined(itemData) && Equals(RPGManager.GetItemCategory(itemData.GetID()), gamedataItemCategory.Weapon);
}

// 9 특전 대상: 일반 무기만 (아이코닉, 레플리카, 퀘스트 아이템 제외)
public static func TCO_IsLearnableWeapon(itemData: wref<gameItemData>) -> Bool {
  return TCO_IsWeaponItem(itemData)
    && !itemData.HasTag(n"IconicWeapon")
    && !itemData.HasTag(n"TCO_Replica")
    && !itemData.HasTag(n"Quest");
}

// 20 특전 원본 후보: 아이코닉 무기이면서 레플리카가 아닌 것
public static func TCO_IsOriginalIconic(itemData: wref<gameItemData>) -> Bool {
  return TCO_IsWeaponItem(itemData)
    && itemData.HasTag(n"IconicWeapon")
    && !itemData.HasTag(n"TCO_Replica");
}

// 기반 무기 판정 (레코드가 아니라 "모델" 기준):
//   1) 레코드가 매핑의 기반 무기와 같다 (Items.Preset_Burya_Default 등)
//   2) 9 특전 티어 레코드(<모델>_TCO_T*)의 TCO_model 이 기반 무기와 같다 (9 특전으로 제작한 무기)
//   3) 같은 무기 종류 + 같은 표시 이름의 일반 무기 (외형 변형 Pimp/Neon/Military, 바닐라 Craftable_* 제작품 등)
//   아이코닉과 레플리카는 기반 무기가 될 수 없다.
//   4) 기반 무기가 신화 무기인 경우(fusion 프리셋, 무기별 비용 재정의): 같은 표시 이름의 신화 무기 (등급 변형 포함). 레플리카는 제외.
public static func TCO_IsBaseModelInstance(itemData: wref<gameItemData>, baseID: TweakDBID) -> Bool {
  if !IsDefined(itemData) || !TDBID.IsValid(baseID) { return false; }
  let recordID = ItemID.GetTDBID(itemData.GetID());
  if itemData.HasTag(n"TCO_Replica") { return false; }
  if recordID == baseID { return true; }
  if TweakDBInterface.GetForeignKey(recordID + t".TCO_model", TDBID.None()) == baseID { return true; }
  let record = TweakDBInterface.GetItemRecord(recordID);
  let base = TweakDBInterface.GetItemRecord(baseID);
  if !IsDefined(record) || !IsDefined(base) { return false; }
  if base.TagsContains(n"IconicWeapon") {
    return itemData.HasTag(n"IconicWeapon") && Equals(record.DisplayName(), base.DisplayName());
  }
  if itemData.HasTag(n"IconicWeapon") { return false; }
  return Equals(record.ItemType().Type(), base.ItemType().Type())
    && Equals(record.DisplayName(), base.DisplayName());
}

// 회수 대상 부품: 개조부품 / 조준경 / 총구 (더미 부품, 본체 부품 제외)
public static func TCO_IsReturnablePart(record: wref<Item_Record>) -> Bool {
  if !IsDefined(record) { return false; }
  if record.TagsContains(n"DummyPart") || record.TagsContains(n"parentPart") { return false; }
  let type = record.ItemType().Type();
  return RPGManager.IsWeaponMod(type)
    || RPGManager.IsScopeAttachment(type)
    || Equals(type, gamedataItemType.Prt_Muzzle)
    || Equals(type, gamedataItemType.Prt_HandgunMuzzle)
    || Equals(type, gamedataItemType.Prt_RifleMuzzle);
}

public static func TCO_ContainsAttachment(list: script_ref<array<ItemAttachments>>, itemID: ItemID) -> Bool {
  let attachments = Deref(list);
  for att in attachments {
    if att.itemID == itemID { return true; }
  }
  return false;
}

// 무기에 장착된 회수 가능 부품을 restored 목록에 추가한다 (분해 판정 공용 로직)
public static func TCO_CollectRetrievableParts(itemData: wref<gameItemData>, restored: script_ref<array<ItemAttachments>>) -> Void {
  if !IsDefined(itemData) { return; }
  let slots = RPGManager.GetAttachmentSlotIDs();
  let modSlots = RPGManager.GetModsSlotIDs(itemData.GetItemType());
  for modSlot in modSlots {
    ArrayPush(slots, modSlot);
  }
  for slot in slots {
    if itemData.HasPartInSlot(slot) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slot);
      let partID = InnerItemData.GetItemID(part);
      let partRecord = InnerItemData.GetStaticData(part);
      if ItemID.IsValid(partID) && TCO_IsReturnablePart(partRecord) && !TCO_ContainsAttachment(restored, partID) {
        ArrayPush(Deref(restored), ItemAttachments.Create(partID, slot));
      }
    }
  }
}

// 바닐라 제작 XP 상수 (Constants.CraftingSystem.*IngredientXP)
public static func TCO_IngredientXP(record: wref<Item_Record>) -> Int32 {
  if !IsDefined(record) { return 0; }
  switch RPGManager.GetItemQualityFromRecord(record) {
    case gamedataQuality.Common: return TweakDBInterface.GetInt(t"Constants.CraftingSystem.commonIngredientXP", 0);
    case gamedataQuality.Uncommon: return TweakDBInterface.GetInt(t"Constants.CraftingSystem.uncommonIngredientXP", 0);
    case gamedataQuality.Rare: return TweakDBInterface.GetInt(t"Constants.CraftingSystem.rareIngredientXP", 0);
    case gamedataQuality.Epic: return TweakDBInterface.GetInt(t"Constants.CraftingSystem.epicIngredientXP", 0);
    case gamedataQuality.Legendary: return TweakDBInterface.GetInt(t"Constants.CraftingSystem.legendaryIngredientXP", 0);
    default: return 0;
  }
}

// 레플리카의 티어 스탯을 원본과 맞춘다 (업그레이드 횟수 + 등급/플러스 차이 보정)
public static func TCO_MatchTier(ss: ref<StatsSystem>, original: wref<gameItemData>, replica: wref<gameItemData>) -> Void {
  if !IsDefined(ss) || !IsDefined(original) || !IsDefined(replica) { return; }
  let target = replica.GetStatsObjectID();
  let upgrades = original.GetStatValueByType(gamedataStatType.WasItemUpgraded);
  ss.RemoveAllModifiers(target, gamedataStatType.WasItemUpgraded, true);
  ss.AddSavedModifier(target, RPGManager.CreateStatModifier(gamedataStatType.WasItemUpgraded, gameStatModifierType.Additive, upgrades));
  let qualityDelta = original.GetStatValueByType(gamedataStatType.Quality) - replica.GetStatValueByType(gamedataStatType.Quality);
  if AbsF(qualityDelta) > 0.01 {
    ss.AddSavedModifier(target, RPGManager.CreateStatModifier(gamedataStatType.Quality, gameStatModifierType.Additive, qualityDelta));
  }
  let plusDelta = original.GetStatValueByType(gamedataStatType.IsItemPlus) - replica.GetStatValueByType(gamedataStatType.IsItemPlus);
  if AbsF(plusDelta) > 0.01 {
    ss.AddSavedModifier(target, RPGManager.CreateStatModifier(gamedataStatType.IsItemPlus, gameStatModifierType.Additive, plusDelta));
  }
}

// ---------------------------------------------------------------------------
// 시스템 본체
// ---------------------------------------------------------------------------
public class TechieCraftingOverhaul extends ScriptableSystem {
  // 복제 기록 (세이브에 저장). 무기 "종류" 기준 = displayName LocKey 로 판정하고 레코드도 함께 기록한다.
  private persistent let m_clonedNames: array<CName>;
  private persistent let m_clonedRecords: array<TweakDBID>;
  private let m_player: wref<PlayerPuppet>;
  private let m_syncing: Bool;
  // Mod Settings 값을 담는 인스턴스 (Mod Settings 가 있을 때만 TCO_ActiveSettings 가 요청한다)
  private let m_settings: ref<TCO_Settings>;
  // 포인트 없이 지급한 특전의 enumName (세이브에 저장). 여기 있는 특전은 팔리거나 초기화되어도 포인트를 돌려주지 않는다.
  private persistent let m_freePerks: array<CName>;
  // 세션이 완전히 올라온 뒤(플레이어 부착 + 1초)에만 자동 해금을 동기화한다. 복원 도중에는 m_freePerks 가 아직
  // 비어 있을 수 있고, 그 상태로 동기화하면 이미 공짜로 받은 특전을 "포인트로 산 것"으로 보고 환불해 버린다.
  private let m_ready: Bool;
  private let m_freeSyncing: Bool;
  private let m_lastFreeMode: Bool;

  public static func GetInstance(gi: GameInstance) -> ref<TechieCraftingOverhaul> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"TechieCraftingOverhaul") as TechieCraftingOverhaul;
  }

  // 새 인스턴스는 Mod Settings 가 써 넣은 클래스 기본값(= 저장된 설정)으로 만들어지고,
  // 리스너로 등록해 두면 메뉴에서 값을 바꿀 때 필드가 바로 갱신된다.
  public func GetSettings() -> ref<TCO_Settings> {
    if !IsDefined(this.m_settings) {
      this.m_settings = new TCO_Settings();
      TCO_RegisterSettingsListener(this.m_settings);
    }
    return this.m_settings;
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.m_player = request.owner as PlayerPuppet;
    this.m_ready = false;
    let readyCallback = new TCO_ReadyCallback();
    readyCallback.system = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(readyCallback, 1.0, false);
    TCO_Log("Player attached. Tech points = " + IntToString(this.GetTechPoints()) + ", tree mode = " + ToString(this.IsTreeModeActive()) + ", cloned types = " + IntToString(ArraySize(this.m_clonedNames)));
  }

  private func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
    this.m_player = null;
    this.m_ready = false;
  }

  public func OnSessionReady() -> Void {
    this.m_ready = true;
    this.SyncFreePerks();
  }

  public func GetPlayerRef() -> wref<PlayerPuppet> {
    if !IsDefined(this.m_player) {
      this.m_player = GetPlayer(this.GetGameInstance());
    }
    return this.m_player;
  }

  // --- 특전 판정 -----------------------------------------------------------
  public func GetTechPoints() -> Int32 {
    let player = this.GetPlayerRef();
    if !IsDefined(player) { return 0; }
    let data = PlayerDevelopmentSystem.GetData(player);
    if !IsDefined(data) { return 0; }
    return data.GetAttributePoints(gamedataAttributeDataType.TechnicalAbilityAttributeData);
  }

  private func IsPerkEnabled(perk: TCO_Perk) -> Bool {
    switch perk {
      case TCO_Perk.Techie9: return TCO_Config.Perk9Enabled();
      case TCO_Perk.Removable15: return TCO_Config.Perk15Enabled();
      case TCO_Perk.Rigging20: return TCO_Config.Perk20Enabled();
      default: return false;
    }
  }

  private func GetPerkAttributeThreshold(perk: TCO_Perk) -> Int32 {
    switch perk {
      case TCO_Perk.Techie9: return TCO_Config.Perk9Attribute();
      case TCO_Perk.Removable15: return TCO_Config.Perk15Attribute();
      case TCO_Perk.Rigging20: return TCO_Config.Perk20Attribute();
      default: return 999;
    }
  }

  // 트리 노드가 실제로 존재하면(프레임워크 설치) 그 노드가 판정의 기준이 된다
  public func IsTreeModeActive() -> Bool {
    if Equals(TCO_Config.PerkMode(), n"attribute") { return false; }
    let perkType: gamedataNewPerkType;
    return TCO_ResolvePerkType(TCO_Perk.Techie9, perkType);
  }

  public func IsPerkActive(perk: TCO_Perk) -> Bool {
    if !this.IsPerkEnabled(perk) { return false; }
    let mode = TCO_Config.PerkMode();
    let perkType: gamedataNewPerkType;
    if NotEquals(mode, n"attribute") && TCO_ResolvePerkType(perk, perkType) {
      let player = this.GetPlayerRef();
      if !IsDefined(player) { return false; }
      let data = PlayerDevelopmentSystem.GetData(player);
      if !IsDefined(data) { return false; }
      let free = TCO_Config.PerkFreeUnlock();
      if (free && !this.m_lastFreeMode) || (!free && this.m_lastFreeMode) {
        // 옵션이 바뀐 것을 변경 알림으로 받지 못했을 때의 안전망
        this.SyncFreePerks();
      }
      if free {
        // 자동 해금: 노드 표시가 아직 갱신되지 않았더라도 효과는 능력치 기준으로 판정한다
        return data.HasEnoughtAttributePoints(perkType);
      }
      return data.IsNewPerkBought(perkType) > 0;
    }
    if Equals(mode, n"tree") {
      return false;
    }
    return this.GetTechPoints() >= this.GetPerkAttributeThreshold(perk);
  }

  // --- 복제 기록 -------------------------------------------------------------
  public func IsClonedRecord(originalID: TweakDBID) -> Bool {
    let record = TweakDBInterface.GetItemRecord(originalID);
    if !IsDefined(record) { return false; }
    return ArrayContains(this.m_clonedNames, record.DisplayName()) || ArrayContains(this.m_clonedRecords, originalID);
  }

  public func MarkCloned(originalID: TweakDBID) -> Void {
    let record = TweakDBInterface.GetItemRecord(originalID);
    if IsDefined(record) && !ArrayContains(this.m_clonedNames, record.DisplayName()) {
      ArrayPush(this.m_clonedNames, record.DisplayName());
    }
    if !ArrayContains(this.m_clonedRecords, originalID) {
      ArrayPush(this.m_clonedRecords, originalID);
    }
  }

  public func GetClonedCount() -> Int32 {
    return ArraySize(this.m_clonedNames);
  }

  // --- 9 특전: 레시피 습득 (TCO_Perk9_Recipes.reds 의 후킹이 호출) ----------------
  // effectiveTier: 분해한 무기의 EffectiveTier 스탯 (0 = 티어1 ... 10 = 티어5++)
  public func LearnRecipesFromWeapon(presetID: TweakDBID, effectiveTier: Int32) -> Void {
    let gi = this.GetGameInstance();
    let modelID = TweakDBInterface.GetForeignKey(presetID + t".TCO_model", TDBID.None());
    if !TDBID.IsValid(modelID) {
      TCO_Log("No crafting model registered for disassembled preset " + TDBID.ToStringDEBUG(presetID));
      return;
    }
    let tiers = TweakDBInterface.GetForeignKeyArray(modelID + t".TCO_tiers");
    if ArraySize(tiers) == 0 {
      TCO_Log("Model has no tier records: " + TDBID.ToStringDEBUG(modelID));
      return;
    }
    let craftingSystem = CraftingSystem.GetInstance(gi);
    if !IsDefined(craftingSystem) { return; }
    let book = craftingSystem.GetPlayerCraftBook();
    if !IsDefined(book) { return; }
    let known = book.GetCraftableItems();
    let mode = TCO_Config.RecipeTierMode();
    let itemTier = Clamp(effectiveTier, 0, ArraySize(tiers) - 1);
    let labels = "";
    let added = 0;
    let i = 0;
    while i < ArraySize(tiers) {
      // equal: 같은 티어만 / upto: 이하 전부 / all: 전부
      let wanted = Equals(mode, n"all") || (Equals(mode, n"upto") && i <= itemTier) || (!Equals(mode, n"all") && !Equals(mode, n"upto") && i == itemTier);
      if wanted {
        if book.KnowsRecipe(tiers[i]) {
          this.DebugRecipeSkip(gi, i, "already learned from this mod");
        } else {
          let equivalent = this.FindEquivalentRecipe(known, tiers[i]);
          if TDBID.IsValid(equivalent) {
            this.DebugRecipeSkip(gi, i, "player already knows " + TDBID.ToStringDEBUG(equivalent));
          } else {
            book.AddRecipe(tiers[i]);
            if added > 0 { labels += ", "; }
            labels += TCO_Text.TierLabel(i);
            added += 1;
          }
        }
      }
      i += 1;
    }
    TCO_Log("Learned " + IntToString(added) + " tier recipes for " + TDBID.ToStringDEBUG(modelID) + " (item tier " + IntToString(itemTier) + ", mode " + NameToString(mode) + ")");
    if added > 0 {
      TCO_Notify(gi, TCO_Text.RecipeLearned(gi, TCO_ItemName(TweakDBInterface.GetItemRecord(modelID)), labels));
    }
  }

  // 플레이어의 제작 도감(알고 있고 숨겨지지 않은 레시피)에 같은 "이름 + 등급" 의 일반 무기 레시피
  // (상점에서 산 바닐라 레시피, 게임 시작 시 기본으로 주어지는 레시피, 다른 모드의 레시피)가 있으면 그 레코드를 돌려준다.
  // 게임 데이터에 레시피가 정의되어 있기만 한 경우는 해당하지 않는다. known 은 CraftBook.GetCraftableItems() 의 결과다.
  public func FindEquivalentRecipe(known: array<wref<Item_Record>>, tierID: TweakDBID) -> TweakDBID {
    let tierRecord = TweakDBInterface.GetItemRecord(tierID);
    if !IsDefined(tierRecord) { return TDBID.None(); }
    for record in known {
      if IsDefined(record)
        && !record.TagsContains(n"IconicWeapon")
        && Equals(record.DisplayName(), tierRecord.DisplayName())
        && Equals(record.Quality().Type(), tierRecord.Quality().Type()) {
        return record.GetID();
      }
    }
    return TDBID.None();
  }

  public func HasEquivalentRecipe(known: array<wref<Item_Record>>, tierID: TweakDBID) -> Bool {
    return TDBID.IsValid(this.FindEquivalentRecipe(known, tierID));
  }

  // debugLog 가 켜져 있으면 건너뛴 티어와 이유를 화면 알림으로 보여준다
  private func DebugRecipeSkip(gi: GameInstance, tierIndex: Int32, reason: String) -> Void {
    let text = "recipe skipped (" + TCO_Text.TierLabel(tierIndex) + "): " + reason;
    TCO_Log(text);
    if TCO_Config.DebugLog() {
      TCO_Notify(gi, "[TCO] " + text);
    }
  }

  // --- 포인트 없이 자동 해금 (TCO_FreePerks.reds 의 후킹이 호출) ----------------
  // 옵션이 켜져 있고 특전이 트리 노드로 존재할 때만 동작한다 (능력치 모드는 원래 자동이다)
  public func IsFreeUnlockActive() -> Bool {
    return TCO_Config.PerkFreeUnlock() && this.IsTreeModeActive();
  }

  public func IsFreePerk(perkType: gamedataNewPerkType) -> Bool {
    let record = RPGManager.GetNewPerkRecord(perkType);
    return IsDefined(record) && ArrayContains(this.m_freePerks, record.EnumName());
  }

  // 특전이 팔릴 때 환불 직전에 호출된다. 공짜로 지급한 특전이면 표시를 지우고 true (= 환불하지 않는다).
  public func ConsumeFreePerkFlag(perkType: gamedataNewPerkType) -> Bool {
    let record = RPGManager.GetNewPerkRecord(perkType);
    if !IsDefined(record) { return false; }
    let enumName = record.EnumName();
    if !ArrayContains(this.m_freePerks, enumName) { return false; }
    ArrayRemove(this.m_freePerks, enumName);
    return true;
  }

  // 자동 해금 상태를 현재 설정/능력치에 맞춘다. 세이브 로드 직후, 속성 값 변경 시, 옵션 변경 시 호출된다.
  //   옵션 켜짐 + 요구치 충족 : 미보유면 공짜로 지급. 포인트로 샀던 특전은 포인트를 돌려주고 공짜 특전으로 바꾼다.
  //   옵션 꺼짐 또는 요구치 미달 : 공짜로 받았던 특전을 환불 없이 회수한다. 포인트로 산 특전은 건드리지 않는다.
  // 조니/브레인댄스처럼 플레이어가 대역(replacer)일 때는 건드리지 않는다. 대역은 자기 성장 데이터를 따로 갖고 있어서,
  // 그 데이터로 맞추면 V 의 공짜 특전 표시가 지워지고 돌아왔을 때 포인트를 잘못 환불하게 된다.
  public func SyncFreePerks() -> Void {
    if !this.m_ready || this.m_freeSyncing { return; }
    let player = this.GetPlayerRef();
    if !IsDefined(player) || player.IsReplacer() { return; }
    let devData = PlayerDevelopmentSystem.GetData(player);
    if !IsDefined(devData) { return; }
    this.m_freeSyncing = true;
    this.m_lastFreeMode = TCO_Config.PerkFreeUnlock();
    let free = this.IsFreeUnlockActive();
    let gi = this.GetGameInstance();
    let perkType: gamedataNewPerkType;

    // 회수는 뒤에서부터 (20 -> 15 -> 9)
    let revokeOrder: array<TCO_Perk>;
    ArrayPush(revokeOrder, TCO_Perk.Rigging20);
    ArrayPush(revokeOrder, TCO_Perk.Removable15);
    ArrayPush(revokeOrder, TCO_Perk.Techie9);
    let revoked = false;
    for perk in revokeOrder {
      if TCO_ResolvePerkType(perk, perkType) {
        let enumName = TCO_PerkEnumName(perk);
        let owned = devData.IsNewPerkBought(perkType) > 0;
        let flagged = ArrayContains(this.m_freePerks, enumName);
        let eligible = free && devData.HasEnoughtAttributePoints(perkType);
        if flagged && !owned {
          ArrayRemove(this.m_freePerks, enumName);
        } else {
          if flagged && !eligible {
            this.RevokeFreePerk(devData, perkType);
            revoked = true;
            TCO_Log("Free perk revoked: " + NameToString(enumName));
          }
        }
      }
    }
    // 회수한 뒤에는 바닐라 초기화처럼, 요구치나 선행 특전이 더 이상 충족되지 않는 미보유 노드를 잠근다 (9 -> 15 -> 20)
    if revoked {
      let lockOrder: array<TCO_Perk>;
      ArrayPush(lockOrder, TCO_Perk.Techie9);
      ArrayPush(lockOrder, TCO_Perk.Removable15);
      ArrayPush(lockOrder, TCO_Perk.Rigging20);
      for perk in lockOrder {
        if TCO_ResolvePerkType(perk, perkType)
          && devData.IsNewPerkUnlocked(perkType)
          && devData.IsNewPerkBought(perkType) == 0
          && !this.PerkRequirementsMet(devData, perkType)
          && devData.LockNewPerk(perkType) {
          let lockedEvent = new NewPerkLockedEvent();
          lockedEvent.perkType = perkType;
          GameInstance.GetUISystem(gi).QueueEvent(lockedEvent);
        }
      }
    }

    // 지급은 앞에서부터 (9 -> 15 -> 20)
    if free {
      let grantOrder: array<TCO_Perk>;
      ArrayPush(grantOrder, TCO_Perk.Techie9);
      ArrayPush(grantOrder, TCO_Perk.Removable15);
      ArrayPush(grantOrder, TCO_Perk.Rigging20);
      for perk in grantOrder {
        if TCO_ResolvePerkType(perk, perkType) && devData.HasEnoughtAttributePoints(perkType) {
          let enumName = TCO_PerkEnumName(perk);
          if devData.IsNewPerkBought(perkType) > 0 {
            if !ArrayContains(this.m_freePerks, enumName) {
              // 포인트로 샀던 특전: 포인트를 돌려주고 공짜 특전으로 바꾼다
              devData.AddDevelopmentPoints(1, gamedataDevelopmentPointType.Primary);
              ArrayPush(this.m_freePerks, enumName);
              TCO_Log("Paid perk converted to free, 1 point refunded: " + NameToString(enumName));
            }
          } else {
            if this.GrantFreePerk(devData, perkType, enumName) {
              let record = RPGManager.GetNewPerkRecord(perkType);
              TCO_Notify(gi, TCO_Text.PerkAutoUnlocked(gi, GetLocalizedText(record.Loc_name_key())));
              TCO_Log("Free perk granted: " + NameToString(enumName));
            }
          }
        }
      }
    }
    this.m_freeSyncing = false;
  }

  private func GrantFreePerk(data: ref<PlayerDevelopmentData>, perkType: gamedataNewPerkType, enumName: CName) -> Bool {
    let ui = GameInstance.GetUISystem(this.GetGameInstance());
    if !data.IsNewPerkUnlocked(perkType) && data.UnlockNewPerk(perkType) {
      let unlockedEvent = new NewPerkUnlockedEvent();
      unlockedEvent.perkType = perkType;
      ui.QueueEvent(unlockedEvent);
    }
    // forceBuy = true : 포인트 잔량/선행 특전 검사를 건너뛰고 포인트도 차감하지 않는 바닐라 경로
    if !data.BuyNewPerk(perkType, true) {
      return false;
    }
    ArrayPush(this.m_freePerks, enumName);
    let boughtEvent = new NewPerkBoughtEvent();
    boughtEvent.perkType = perkType;
    ui.QueueEvent(boughtEvent);
    return true;
  }

  // 환불 없이 회수한다 (환불 차단은 ReturnDevelopmentPointForSoldPerk 후킹이 m_freePerks 표시를 보고 처리).
  private func RevokeFreePerk(data: ref<PlayerDevelopmentData>, perkType: gamedataNewPerkType) -> Void {
    let ui = GameInstance.GetUISystem(this.GetGameInstance());
    let player = this.GetPlayerRef();
    let sold: Int32;
    let rounds = 0;
    while rounds < 4 && data.ForceSellNewPerk(perkType, sold) {
      let soldEvent = new NewPerkSoldEvent();
      soldEvent.perkType = perkType;
      soldEvent.perkLevelSold = sold;
      ui.QueueEvent(soldEvent);
      if IsDefined(player) {
        player.QueueEvent(soldEvent);
      }
      rounds += 1;
    }
  }

  // 바닐라의 해금 조건과 같다: 속성 요구치 + 선행 특전 최대 레벨
  private func PerkRequirementsMet(data: ref<PlayerDevelopmentData>, perkType: gamedataNewPerkType) -> Bool {
    if !data.HasEnoughtAttributePoints(perkType) { return false; }
    let record = RPGManager.GetNewPerkRecord(perkType);
    if !IsDefined(record) { return false; }
    let required: array<wref<NewPerk_Record>>;
    record.RequiresPerks(required);
    for requiredPerk in required {
      if data.IsNewPerkBought(requiredPerk.Type()) < requiredPerk.GetLevelsCount() {
        return false;
      }
    }
    return true;
  }

  // --- 20 특전: 레플리카 (TCO_Perk20_Replica.reds 의 후킹이 호출) ----------------
  // 소지 중인 원본 아이코닉 중 요구 티어 이상인 것 (가장 높은 티어 우선)
  public func FindOwnedOriginal(originalID: TweakDBID) -> ItemID {
    let player = this.GetPlayerRef();
    if !IsDefined(player) { return ItemID.None(); }
    let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
    let items: array<wref<gameItemData>>;
    ts.GetItemList(player, items);
    let best: ItemID = ItemID.None();
    let bestTier: Float = -1.0;
    let required = TCO_Config.ReplicaRequiredTier();
    for item in items {
      if IsDefined(item) && ItemID.GetTDBID(item.GetID()) == originalID && TCO_IsOriginalIconic(item) {
        let tier = TCO_GetEffectiveTier(item);
        if tier >= required && tier > bestTier {
          best = item.GetID();
          bestTier = tier;
        }
      }
    }
    return best;
  }

  // 기반 무기로 쓸 수 있는 인스턴스인가: 모델 일치, 요구 티어 이상, 장착 중이 아니고, 퀘스트 아이템이 아님
  public func IsUsableBase(item: wref<gameItemData>, baseID: TweakDBID) -> Bool {
    let player = this.GetPlayerRef();
    return IsDefined(item) && IsDefined(player)
      && TCO_IsBaseModelInstance(item, baseID)
      && !item.HasTag(n"Quest")
      && !item.HasTag(n"UnequipBlocked")
      && !RPGManager.IsItemEquipped(player, item.GetID())
      && TCO_GetEffectiveTier(item) >= TCO_Config.ReplicaRequiredTier();
  }

  // 소모할 기반 무기 인스턴스: 사용 가능한 것 중 가장 낮은 티어
  public func FindBaseInstance(baseID: TweakDBID, exclude: array<ItemID>) -> ItemID {
    let player = this.GetPlayerRef();
    if !IsDefined(player) { return ItemID.None(); }
    let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
    let items: array<wref<gameItemData>>;
    ts.GetItemList(player, items);
    let best: ItemID = ItemID.None();
    let bestTier: Float = 1000.0;
    for item in items {
      if !ArrayContains(exclude, item.GetID()) && this.IsUsableBase(item, baseID) {
        let tier = TCO_GetEffectiveTier(item);
        if tier < bestTier {
          best = item.GetID();
          bestTier = tier;
        }
      }
    }
    return best;
  }

  // 사용 가능한 기반 무기 개수 (제작 UI 재료 줄의 보유 수량 표시용)
  public func CountUsableBases(baseID: TweakDBID) -> Int32 {
    let player = this.GetPlayerRef();
    if !IsDefined(player) { return 0; }
    let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
    let items: array<wref<gameItemData>>;
    ts.GetItemList(player, items);
    let count = 0;
    for item in items {
      if this.IsUsableBase(item, baseID) {
        count += 1;
      }
    }
    return count;
  }

  // 무기별 비용 재정의(TCO.ReplicaCost.<아이코닉>)가 걸린 레플리카인가
  public func HasCustomReplicaCost(replicaID: TweakDBID) -> Bool {
    return TweakDBInterface.GetBool(replicaID + t".TCO_customCost", false);
  }

  // 레플리카 한 벌에 소모되는 무기 목록 (같은 무기가 여러 번 나오면 그만큼 필요).
  // 무기별 재정의가 있으면 그 레시피의 무기 재료, 없으면 현재 프리셋대로 조합한다:
  //   매핑된 기반 무기(기반 무기를 쓰는 프리셋일 때) + 원본 추가 소모분.
  // 프리셋은 게임 중에 바뀔 수 있으므로(Mod Settings) 로딩 시 고정하지 않고 물을 때마다 계산한다.
  public func GetReplicaBases(replicaID: TweakDBID) -> array<TweakDBID> {
    if this.HasCustomReplicaCost(replicaID) {
      return TweakDBInterface.GetForeignKeyArray(replicaID + t".TCO_customBases");
    }
    let bases: array<TweakDBID>;
    if TCO_Config.ReplicaUseBaseWeapon() {
      bases = TweakDBInterface.GetForeignKeyArray(replicaID + t".TCO_mappedBases");
    }
    let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
    if TDBID.IsValid(originalID) {
      let copies = TCO_Config.ReplicaOriginalCopies();
      let n = 0;
      while n < copies {
        ArrayPush(bases, originalID);
        n += 1;
      }
    }
    return bases;
  }

  // 재료 줄에 표시할 보유 수량. 원본으로 남겨 둘 한 자루는 재료로 쓸 수 없으므로 세지 않는다
  // (원본을 재료로도 요구하는 fusion 프리셋에서 "2/2 인데 제작 불가"가 되지 않도록).
  public func CountAvailableBases(replicaID: TweakDBID, baseID: TweakDBID) -> Int32 {
    let count = this.CountUsableBases(baseID);
    let player = this.GetPlayerRef();
    let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
    let originalItem = this.FindOwnedOriginal(originalID);
    if IsDefined(player) && ItemID.IsValid(originalItem) {
      let originalData = GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemData(player, originalItem);
      if this.IsUsableBase(originalData, baseID) {
        count -= 1;
      }
    }
    return Max(count, 0);
  }

  // 복제 조건 (모두 충족): 특전 활성, 원본 소지(티어5+), 필요한 무기 소지(티어5+, 목록 수만큼), 미복제 종류
  // 부품 수량은 TCO_Perk20_Replica.reds 가 따로 검사한다.
  public func CanCraftReplica(replicaID: TweakDBID) -> Bool {
    if !this.IsPerkActive(TCO_Perk.Rigging20) { return false; }
    let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
    if !TDBID.IsValid(originalID) { return false; }
    if this.IsClonedRecord(originalID) { return false; }
    let originalItem = this.FindOwnedOriginal(originalID);
    if !ItemID.IsValid(originalItem) { return false; }
    let bases = this.GetReplicaBases(replicaID);
    let chosen: array<ItemID>;
    ArrayPush(chosen, originalItem);
    for baseID in bases {
      let instance = this.FindBaseInstance(baseID, chosen);
      if !ItemID.IsValid(instance) { return false; }
      ArrayPush(chosen, instance);
    }
    return true;
  }

  // 제작 목록 동기화: 특전이 활성이고 요구 티어 이상의 원본 아이코닉을 소지하면 그 레플리카 레시피를 추가/표시한다.
  // 재료(기반 무기, 부품)는 표시 조건이 아니며 제작 버튼 활성(CanCraftReplica)에서만 검사한다. 조건이 깨진 레시피는 숨긴다.
  public func SyncReplicaRecipes() -> Void {
    if this.m_syncing { return; }
    this.m_syncing = true;
    let gi = this.GetGameInstance();
    let craftingSystem = CraftingSystem.GetInstance(gi);
    let player = this.GetPlayerRef();
    if IsDefined(craftingSystem) && IsDefined(craftingSystem.GetPlayerCraftBook()) && IsDefined(player) {
      let book = craftingSystem.GetPlayerCraftBook();
      let wanted: array<TweakDBID>;
      let perkActive = this.IsPerkActive(TCO_Perk.Rigging20);
      let originals = 0;
      if perkActive {
        let ts = GameInstance.GetTransactionSystem(gi);
        let items: array<wref<gameItemData>>;
        ts.GetItemList(player, items);
        let required = TCO_Config.ReplicaRequiredTier();
        for item in items {
          if TCO_IsOriginalIconic(item) && TCO_GetEffectiveTier(item) >= required {
            originals += 1;
            let originalID = ItemID.GetTDBID(item.GetID());
            let replicaID = TweakDBInterface.GetForeignKey(originalID + t".TCO_replica", TDBID.None());
            if TDBID.IsValid(replicaID)
              && !ArrayContains(wanted, replicaID)
              && !this.IsClonedRecord(originalID) {
              ArrayPush(wanted, replicaID);
            }
          }
        }
      }
      if TCO_Config.DebugLog() {
        let summary = "replica sync: perk=" + ToString(perkActive) + ", originals(T5+)=" + IntToString(originals) + ", listed=" + IntToString(ArraySize(wanted));
        TCO_Log(summary);
        TCO_Notify(gi, "[TCO] " + summary);
      }
      for replicaID in wanted {
        if book.KnowsRecipe(replicaID) {
          book.HideRecipe(replicaID, false);
        } else {
          book.AddRecipe(replicaID);
        }
      }
      let visible = book.GetCraftableItems();
      for record in visible {
        if IsDefined(record) && record.TagsContains(n"TCO_Replica") && !ArrayContains(wanted, record.GetID()) {
          book.HideRecipe(record.GetID(), true);
        }
      }
    }
    this.m_syncing = false;
  }

}
