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
// 설정 (r6/tweaks/TechieCraftingOverhaul/TCO_Config.yaml 의 flat 을 읽는다)
// ---------------------------------------------------------------------------
public abstract class TCO_Config {
  public static func PerkMode() -> CName { return TweakDBInterface.GetCName(t"TCO.Config.perkMode", n"auto"); }
  public static func Perk9Enabled() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.perk9Enabled", true); }
  public static func Perk15Enabled() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.perk15Enabled", true); }
  public static func Perk20Enabled() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.perk20Enabled", true); }
  public static func Perk9Attribute() -> Int32 { return TweakDBInterface.GetInt(t"TCO.Config.perk9Attribute", 9); }
  public static func Perk15Attribute() -> Int32 { return TweakDBInterface.GetInt(t"TCO.Config.perk15Attribute", 15); }
  public static func Perk20Attribute() -> Int32 { return TweakDBInterface.GetInt(t"TCO.Config.perk20Attribute", 20); }
  public static func ReplicaMaterialItem() -> TweakDBID { return TweakDBInterface.GetForeignKey(t"TCO.Config.replicaMaterialItem", t"Items.LegendaryMaterial1"); }
  public static func ReplicaExcluded() -> array<TweakDBID> { return TweakDBInterface.GetForeignKeyArray(t"TCO.Config.replicaExcluded"); }
  // 레플리카 비용 프리셋: base(기반 무기 + 부품) / parts(부품만) / fusion(원본 2개 추가 소모, 부품 없음) / custom(아래 개별 값)
  public static func ReplicaPreset() -> CName { return TweakDBInterface.GetCName(t"TCO.Config.replicaPreset", n"base"); }
  public static func ReplicaUseBaseWeapon() -> Bool {
    let preset = TCO_Config.ReplicaPreset();
    if Equals(preset, n"parts") || Equals(preset, n"fusion") { return false; }
    if Equals(preset, n"custom") { return TweakDBInterface.GetBool(t"TCO.Config.replicaUseBaseWeapon", true); }
    return true;
  }
  public static func ReplicaOriginalCopies() -> Int32 {
    let preset = TCO_Config.ReplicaPreset();
    if Equals(preset, n"fusion") { return 2; }
    if Equals(preset, n"custom") { return Max(0, TweakDBInterface.GetInt(t"TCO.Config.replicaOriginalCopies", 0)); }
    return 0;
  }
  public static func ReplicaMaterialAmount() -> Int32 {
    if Equals(TCO_Config.ReplicaPreset(), n"fusion") { return 0; }
    return Max(0, TweakDBInterface.GetInt(t"TCO.Config.replicaMaterialAmount", 200));
  }
  public static func ReplicaRequiredTier() -> Float { return Cast<Float>(TweakDBInterface.GetInt(t"TCO.Config.replicaRequiredTier", 8)); }
  public static func ReplicaDisassembleAllowed() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.replicaDisassembleAllowed", false); }
  public static func RecipeTierMode() -> CName { return TweakDBInterface.GetCName(t"TCO.Config.recipeTierMode", n"equal"); }
  public static func Notifications() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.notifications", true); }
  public static func DebugLog() -> Bool { return TweakDBInterface.GetBool(t"TCO.Config.debugLog", false); }
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

  public static func GetInstance(gi: GameInstance) -> ref<TechieCraftingOverhaul> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"TechieCraftingOverhaul") as TechieCraftingOverhaul;
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.m_player = request.owner as PlayerPuppet;
    TCO_Log("Player attached. Tech points = " + IntToString(this.GetTechPoints()) + ", tree mode = " + ToString(this.IsTreeModeActive()) + ", cloned types = " + IntToString(ArraySize(this.m_clonedNames)));
  }

  private func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
    this.m_player = null;
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
      return IsDefined(data) && data.IsNewPerkBought(perkType) > 0;
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
      if wanted && !book.KnowsRecipe(tiers[i]) && !this.HasEquivalentRecipe(known, tiers[i]) {
        book.AddRecipe(tiers[i]);
        if added > 0 { labels += ", "; }
        labels += TCO_Text.TierLabel(i);
        added += 1;
      }
      i += 1;
    }
    TCO_Log("Learned " + IntToString(added) + " tier recipes for " + TDBID.ToStringDEBUG(modelID) + " (item tier " + IntToString(itemTier) + ", mode " + NameToString(mode) + ")");
    if added > 0 {
      TCO_Notify(gi, TCO_Text.RecipeLearned(gi, TCO_ItemName(TweakDBInterface.GetItemRecord(modelID)), labels));
    }
  }

  // 상점 레시피(Items.Craftable_<등급>_<무기>)나 다른 모드의 레시피와 같은 "이름 + 등급" 조합이
  // 이미 제작 목록에 있으면 중복으로 보고 건너뛴다.
  public func HasEquivalentRecipe(known: array<wref<Item_Record>>, tierID: TweakDBID) -> Bool {
    let tierRecord = TweakDBInterface.GetItemRecord(tierID);
    if !IsDefined(tierRecord) { return true; }
    for record in known {
      if IsDefined(record)
        && !record.TagsContains(n"IconicWeapon")
        && Equals(record.DisplayName(), tierRecord.DisplayName())
        && Equals(record.Quality().Type(), tierRecord.Quality().Type()) {
        return true;
      }
    }
    return false;
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

  // 복제 조건 (모두 충족): 특전 활성, 원본 소지(티어5+), 기반 무기 소지(매핑이 있는 무기만, 티어5+, 매핑 수만큼), 미복제 종류
  // 부품 수량은 바닐라 HasIngredients 가 레시피 재료로 검사한다.
  public func CanCraftReplica(replicaID: TweakDBID) -> Bool {
    if !this.IsPerkActive(TCO_Perk.Rigging20) { return false; }
    let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
    if !TDBID.IsValid(originalID) { return false; }
    if this.IsClonedRecord(originalID) { return false; }
    let originalItem = this.FindOwnedOriginal(originalID);
    if !ItemID.IsValid(originalItem) { return false; }
    let bases = TweakDBInterface.GetForeignKeyArray(replicaID + t".TCO_bases");
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
