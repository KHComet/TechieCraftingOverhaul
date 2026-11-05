// ============================================================================
// TCO - TweakXL 스크립트 트윅 (TweakDB 초기화 직후 실행)
//   1) 9 특전용 티어별 제작 레코드 생성
//        모델 M 마다  M_TCO_T1, M_TCO_T1P, M_TCO_T2, ... M_TCO_T5, M_TCO_T5P, M_TCO_T5PP  (11종, EffectiveTier 0..10 순)
//        제작 비용   = 같은 등급의 바닐라 레시피 비용 (Items.Small_<등급>_Crafting_Materials_Weapon)
//                      티어 5+ / 5++ 는 여기에 아이코닉 강화 비용 (Upgrading.Legendary, Upgrading.LegendaryPlus = 티어 5 부품) 을 더함
//        연결 flat   = <프리셋>.TCO_model (모델 레코드), <모델>.TCO_tiers (티어 레코드 배열)
//   2) 20 특전용 레플리카 레코드 생성
//        아이코닉 I 마다  I_TCO_Replica  (Quest 태그 제거, OnLooted 비움, TCO_Replica 태그 추가)
//        제작 재료 = 기반 무기(TCO.BaseMap 또는 자동 매칭) + 설정된 부품
//        연결 flat = <아이코닉>.TCO_replica, <레플리카>.TCO_original / .TCO_bases / .TCO_hasBase
//   주의: 이 단계에서는 GameInstance 를 쓸 수 없다 (TweakDB 접근만 가능).
// ============================================================================

public class TCO_RecordGenerator extends ScriptableTweak {
  protected cb func OnApply() -> Void {
    let generator = new TCO_Generator();
    generator.Run();
  }
}

public class TCO_Generator {
  private let m_qualityChain: array<TweakDBID>;      // 업그레이드 순서의 등급 레코드 (11단계)
  private let m_qualityChainNames: array<String>;    // Upgrading.<이름> 조회용
  private let m_tierChainIndex: array<Int32>;        // 티어1..5++ -> 체인 인덱스
  private let m_tierSuffix: array<TweakDBID>;        // 레코드 접미사
  private let m_tierBaseCostQuality: array<String>;  // 바닥 비용용 바닐라 패키지 등급 이름
  private let m_generatedModels: array<TweakDBID>;
  private let m_costIds: array<TweakDBID>;
  private let m_costAmounts: array<Int32>;
  private let m_tierRecordCount: Int32;
  private let m_modelCount: Int32;
  private let m_replicaCount: Int32;
  private let m_noBaseCount: Int32;

  public func Run() -> Void {
    this.InitTables();
    let records = TweakDBInterface.GetRecords(n"WeaponItem_Record");
    let presets: array<ref<WeaponItem_Record>>;
    let iconics: array<ref<WeaponItem_Record>>;
    let replicaExcluded = TCO_Config.ReplicaExcluded();
    let excludedCount = 0;
    for record in records {
      let weapon = record as WeaponItem_Record;
      if IsDefined(weapon) && !this.IsExcluded(weapon) {
        if weapon.TagsContains(n"IconicWeapon") {
          if ArrayContains(replicaExcluded, weapon.GetID()) {
            excludedCount += 1;
          } else {
            ArrayPush(iconics, weapon);
          }
        } else if this.IsLootable(weapon) {
          ArrayPush(presets, weapon);
        }
      }
    }
    this.GenerateTierRecipes(presets);
    this.GenerateReplicas(iconics, presets);
    this.AttachPerksToTree();
    FTLog("[TCO] TweakDB generation done: " + IntToString(ArraySize(presets)) + " lootable presets, "
      + IntToString(this.m_modelCount) + " models, " + IntToString(this.m_tierRecordCount) + " tier records, "
      + IntToString(this.m_replicaCount) + " replicas (" + IntToString(this.m_noBaseCount) + " without base weapon, "
      + IntToString(excludedCount) + " excluded by config)");
  }

  // --- 특전 노드를 테크 트리에 연결 (Perk Addition Framework 가 있을 때만) -------------
  private func AttachPerksToTree() -> Void {
    if Equals(TCO_Config.PerkMode(), n"attribute") {
      FTLog("[TCO] perkMode = attribute: perk nodes are not attached to the Technical Ability tree");
      return;
    }
    if !IsDefined(Reflection.GetClass(n"PerkAdditionFramework")) {
      FTLog("[TCO] Perk Addition Framework not found: perks fall back to attribute-threshold mode");
      return;
    }
    let attributeID = t"NewPerks.TechnicalAbilityAttributeData";
    let perks = TweakDBInterface.GetForeignKeyArray(attributeID + t".perks");
    let wanted: array<TweakDBID>;
    ArrayPush(wanted, t"NewPerks.TCO_Tech_Johnny");
    ArrayPush(wanted, t"NewPerks.TCO_Tech_Removable");
    ArrayPush(wanted, t"NewPerks.TCO_Tech_Rigging");
    let added = 0;
    for perkID in wanted {
      if IsDefined(TweakDBInterface.GetNewPerkRecord(perkID)) && !ArrayContains(perks, perkID) {
        ArrayPush(perks, perkID);
        added += 1;
      }
    }
    if added > 0 {
      TweakDBManager.SetFlat(attributeID + t".perks", ToVariant(perks));
      TweakDBManager.UpdateRecord(attributeID);
    }
    FTLog("[TCO] Attached " + IntToString(added) + " perk nodes to the Technical Ability tree (Perk Addition Framework detected)");
  }

  private func InitTables() -> Void {
    ArrayPush(this.m_qualityChain, t"Quality.Common");
    ArrayPush(this.m_qualityChain, t"Quality.CommonPlus");
    ArrayPush(this.m_qualityChain, t"Quality.Uncommon");
    ArrayPush(this.m_qualityChain, t"Quality.UncommonPlus");
    ArrayPush(this.m_qualityChain, t"Quality.Rare");
    ArrayPush(this.m_qualityChain, t"Quality.RarePlus");
    ArrayPush(this.m_qualityChain, t"Quality.Epic");
    ArrayPush(this.m_qualityChain, t"Quality.EpicPlus");
    ArrayPush(this.m_qualityChain, t"Quality.Legendary");
    ArrayPush(this.m_qualityChain, t"Quality.LegendaryPlus");
    ArrayPush(this.m_qualityChain, t"Quality.LegendaryPlusPlus");
    ArrayPush(this.m_qualityChainNames, "Common");
    ArrayPush(this.m_qualityChainNames, "CommonPlus");
    ArrayPush(this.m_qualityChainNames, "Uncommon");
    ArrayPush(this.m_qualityChainNames, "UncommonPlus");
    ArrayPush(this.m_qualityChainNames, "Rare");
    ArrayPush(this.m_qualityChainNames, "RarePlus");
    ArrayPush(this.m_qualityChainNames, "Epic");
    ArrayPush(this.m_qualityChainNames, "EpicPlus");
    ArrayPush(this.m_qualityChainNames, "Legendary");
    ArrayPush(this.m_qualityChainNames, "LegendaryPlus");
    ArrayPush(this.m_qualityChainNames, "LegendaryPlusPlus");
    // 티어 인덱스 = EffectiveTier 스탯 (Quality*2 + IsItemPlus): 0 = 티어1, 1 = 티어1+, ... 8 = 티어5, 9 = 5+, 10 = 5++
    let i = 0;
    while i < 11 {
      ArrayPush(this.m_tierChainIndex, i);
      i += 1;
    }
    ArrayPush(this.m_tierSuffix, t"_TCO_T1");
    ArrayPush(this.m_tierSuffix, t"_TCO_T1P");
    ArrayPush(this.m_tierSuffix, t"_TCO_T2");
    ArrayPush(this.m_tierSuffix, t"_TCO_T2P");
    ArrayPush(this.m_tierSuffix, t"_TCO_T3");
    ArrayPush(this.m_tierSuffix, t"_TCO_T3P");
    ArrayPush(this.m_tierSuffix, t"_TCO_T4");
    ArrayPush(this.m_tierSuffix, t"_TCO_T4P");
    ArrayPush(this.m_tierSuffix, t"_TCO_T5");
    ArrayPush(this.m_tierSuffix, t"_TCO_T5P");
    ArrayPush(this.m_tierSuffix, t"_TCO_T5PP");
    // 바닥 비용(바닐라 기본 제작 패키지)의 등급: 플러스 티어는 같은 등급의 패키지를 쓴다
    ArrayPush(this.m_tierBaseCostQuality, "Common");
    ArrayPush(this.m_tierBaseCostQuality, "Common");
    ArrayPush(this.m_tierBaseCostQuality, "Uncommon");
    ArrayPush(this.m_tierBaseCostQuality, "Uncommon");
    ArrayPush(this.m_tierBaseCostQuality, "Rare");
    ArrayPush(this.m_tierBaseCostQuality, "Rare");
    ArrayPush(this.m_tierBaseCostQuality, "Epic");
    ArrayPush(this.m_tierBaseCostQuality, "Epic");
    ArrayPush(this.m_tierBaseCostQuality, "Legendary");
    ArrayPush(this.m_tierBaseCostQuality, "Legendary");
    ArrayPush(this.m_tierBaseCostQuality, "Legendary");
  }

  // --- 분류 -----------------------------------------------------------------
  private func IsExcluded(weapon: ref<WeaponItem_Record>) -> Bool {
    let category = weapon.ItemCategory();
    if !IsDefined(category) || NotEquals(category.Type(), gamedataItemCategory.Weapon) { return true; }
    if weapon.Deprecated() { return true; }
    return weapon.TagsContains(n"Left_Hand")
      || weapon.TagsContains(n"HideInUI")
      || weapon.TagsContains(n"IgnoreInventory")
      || weapon.TagsContains(n"Left_Hand_Retrofix")
      || weapon.TagsContains(n"DiscardOnEmpty")
      || weapon.TagsContains(n"DummyPart")
      || weapon.TagsContains(n"TCO_Craftable")
      || weapon.TagsContains(n"TCO_Replica");
  }

  // 루팅 가능한 일반 프리셋: 랜덤 등급 + 표시 이름 + 외형 정보가 있는 것 (Base_* 추상 레코드 제외)
  private func IsLootable(weapon: ref<WeaponItem_Record>) -> Bool {
    let quality = weapon.Quality();
    if !IsDefined(quality) || NotEquals(quality.Type(), gamedataQuality.Random) { return false; }
    if Equals(weapon.DisplayName(), n"") { return false; }
    return NotEquals(weapon.AppearanceResourceName(), n"") || NotEquals(weapon.AppearanceName(), n"");
  }

  private func RecordName(id: TweakDBID) -> String {
    let name = TDBID.ToStringDEBUG(id);
    if StrBeginsWith(name, "Items.") { return name; }
    return "";
  }

  // 규칙 1: 프리셋 이름에 _Default 가 있으면 디폴트 외형. 이름을 알 수 없으면 visualTags 로 판정.
  private func IsDefaultPreset(weapon: ref<WeaponItem_Record>) -> Bool {
    let name = this.RecordName(weapon.GetID());
    if StrLen(name) > 0 {
      return StrEndsWith(name, "_Default");
    }
    let visualTags = weapon.VisualTags();
    return ArraySize(visualTags) == 1 && Equals(visualTags[0], n"Default");
  }

  // --- 9 특전: 티어별 제작 레코드 ---------------------------------------------
  private func GenerateTierRecipes(presets: array<ref<WeaponItem_Record>>) -> Void {
    for preset in presets {
      let modelID = this.ResolveModel(preset, presets);
      TweakDBManager.SetFlat(preset.GetID() + t".TCO_model", ToVariant(modelID));
      if !ArrayContains(this.m_generatedModels, modelID) {
        let model = TweakDBInterface.GetWeaponItemRecord(modelID);
        if IsDefined(model) {
          this.GenerateTierRecords(model);
          ArrayPush(this.m_generatedModels, modelID);
          this.m_modelCount += 1;
        }
      }
    }
  }

  // 모델 결정: 매핑 테이블 > 자기 자신(_Default) > 같은 이름의 _Default 프리셋 > 자기 자신
  private func ResolveModel(preset: ref<WeaponItem_Record>, presets: array<ref<WeaponItem_Record>>) -> TweakDBID {
    let mapOverride = TweakDBInterface.GetCraftableRecord(t"TCO.ModelMap." + preset.GetID());
    if IsDefined(mapOverride) {
      let items: array<wref<Item_Record>>;
      mapOverride.CraftableItem(items);
      if ArraySize(items) > 0 && IsDefined(items[0]) {
        return items[0].GetID();
      }
    }
    if this.IsDefaultPreset(preset) {
      return preset.GetID();
    }
    let found: TweakDBID = TDBID.None();
    for other in presets {
      if !TDBID.IsValid(found) && Equals(other.DisplayName(), preset.DisplayName()) && this.IsDefaultPreset(other) {
        found = other.GetID();
      }
    }
    if TDBID.IsValid(found) {
      return found;
    }
    return preset.GetID();
  }

  private func GenerateTierRecords(model: ref<WeaponItem_Record>) -> Void {
    let modelID = model.GetID();
    let itemType = model.ItemType().Type();
    let partPresets = this.FilterPartPresets(modelID, itemType);
    let tags = model.Tags();
    ArrayPush(tags, n"TCO_Craftable");
    let tiers: array<TweakDBID>;
    let i = 0;
    while i < 11 {
      let tierID = modelID + this.m_tierSuffix[i];
      if !IsDefined(TweakDBInterface.GetRecord(tierID)) {
        TweakDBManager.CloneRecord(tierID, modelID);
      }
      TweakDBManager.SetFlat(tierID + t".quality", ToVariant(this.m_qualityChain[this.m_tierChainIndex[i]]));
      TweakDBManager.SetFlat(tierID + t".CraftingData", ToVariant(this.GetCostPackage(itemType, i)));
      TweakDBManager.SetFlat(tierID + t".tags", ToVariant(tags));
      TweakDBManager.SetFlat(tierID + t".slotPartListPreset", ToVariant(partPresets));
      TweakDBManager.SetFlat(tierID + t".TCO_model", ToVariant(modelID));
      TweakDBManager.UpdateRecord(tierID);
      ArrayPush(tiers, tierID);
      this.m_tierRecordCount += 1;
      i += 1;
    }
    TweakDBManager.SetFlat(modelID + t".TCO_tiers", ToVariant(tiers));
  }

  // 제작된 무기에 랜덤 조준경/개조부품이 붙지 않도록 (바닐라 Craftable_* 와 동일) 부품 프리셋에서 해당 슬롯을 뺀다
  private func FilterPartPresets(modelID: TweakDBID, itemType: gamedataItemType) -> array<TweakDBID> {
    let result: array<TweakDBID>;
    let flat = TweakDBInterface.GetFlat(modelID + t".slotPartListPreset");
    if !IsDefined(flat) { return result; }
    let entries = FromVariant<array<TweakDBID>>(flat);
    let dropSlots = RPGManager.GetAttachmentSlotIDs();
    let modSlots = RPGManager.GetModsSlotIDs(itemType);
    for modSlot in modSlots {
      ArrayPush(dropSlots, modSlot);
    }
    for entry in entries {
      let slot = TweakDBInterface.GetForeignKey(entry + t".slot", TDBID.None());
      if !ArrayContains(dropSlots, slot) {
        ArrayPush(result, entry);
      }
    }
    return result;
  }

  // --- 제작 비용 패키지 -------------------------------------------------------
  private func GetCostPackage(itemType: gamedataItemType, tier: Int32) -> TweakDBID {
    let typeName = EnumValueToString("gamedataItemType", Cast<Int64>(EnumInt(itemType)));
    let packageID = t"Items.TCO_Cost_" + TDBID.Create(typeName) + this.m_tierSuffix[tier];
    if IsDefined(TweakDBInterface.GetRecord(packageID)) {
      return packageID;
    }
    ArrayClear(this.m_costIds);
    ArrayClear(this.m_costAmounts);
    // 1) 같은 등급의 바닐라 레시피 비용 (플러스 티어도 같은 등급의 패키지를 쓴다). 티어 1~5 는 이것이 전부.
    let basePackage = TweakDBInterface.GetCraftingPackageRecord(t"Items.Small_" + TDBID.Create(this.m_tierBaseCostQuality[tier]) + t"_Crafting_Materials_Weapon");
    if IsDefined(basePackage) {
      let elements: array<wref<RecipeElement_Record>>;
      basePackage.CraftingRecipe(elements);
      for element in elements {
        this.Accumulate(element.Ingredient().GetID(), element.Amount());
      }
    }
    // 2) 티어 5+ / 5++ : 아이코닉을 티어 5 에서 그 티어까지 강화하는 비용을 더한다 (티어 5 부품).
    //    체인 인덱스 8 = 티어 5. Upgrading.Legendary (5 -> 5+), Upgrading.LegendaryPlus (5+ -> 5++)
    let typeUpgrade = TweakDBInterface.GetUpgradingDataRecord(t"Upgrading." + TDBID.Create(typeName));
    let step = 8;
    while step < this.m_tierChainIndex[tier] {
      this.AccumulateUpgrading(typeUpgrade);
      this.AccumulateUpgrading(TweakDBInterface.GetUpgradingDataRecord(t"Upgrading." + TDBID.Create(this.m_qualityChainNames[step])));
      step += 1;
    }
    this.CreatePackageFromAccumulated(packageID);
    return packageID;
  }

  private func AccumulateUpgrading(record: ref<UpgradingData_Record>) -> Void {
    if !IsDefined(record) { return; }
    let elements: array<wref<RecipeElement_Record>>;
    record.Ingredients(elements);
    for element in elements {
      this.Accumulate(element.Ingredient().GetID(), element.Amount());
    }
  }

  private func Accumulate(ingredient: TweakDBID, amount: Int32) -> Void {
    if !TDBID.IsValid(ingredient) || amount <= 0 { return; }
    let i = 0;
    while i < ArraySize(this.m_costIds) {
      if this.m_costIds[i] == ingredient {
        this.m_costAmounts[i] += amount;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_costIds, ingredient);
    ArrayPush(this.m_costAmounts, amount);
  }

  private func CreatePackageFromAccumulated(packageID: TweakDBID) -> Void {
    let elementIDs: array<TweakDBID>;
    let k = 0;
    while k < ArraySize(this.m_costIds) {
      let elementID = packageID + t"_E" + TDBID.Create(IntToString(k));
      if !IsDefined(TweakDBInterface.GetRecord(elementID)) {
        TweakDBManager.CreateRecord(elementID, n"RecipeElement_Record");
      }
      TweakDBManager.SetFlat(elementID + t".ingredient", ToVariant(this.m_costIds[k]));
      TweakDBManager.SetFlat(elementID + t".amount", ToVariant(this.m_costAmounts[k]));
      TweakDBManager.UpdateRecord(elementID);
      ArrayPush(elementIDs, elementID);
      k += 1;
    }
    if !IsDefined(TweakDBInterface.GetRecord(packageID)) {
      TweakDBManager.CreateRecord(packageID, n"CraftingPackage_Record");
    }
    TweakDBManager.SetFlat(packageID + t".craftingRecipe", ToVariant(elementIDs));
    TweakDBManager.UpdateRecord(packageID);
  }

  // --- 20 특전: 레플리카 레코드 -----------------------------------------------
  private func GenerateReplicas(iconics: array<ref<WeaponItem_Record>>, presets: array<ref<WeaponItem_Record>>) -> Void {
    for iconic in iconics {
      let originalID = iconic.GetID();
      let replicaID = originalID + t"_TCO_Replica";
      if !IsDefined(TweakDBInterface.GetRecord(replicaID)) {
        TweakDBManager.CloneRecord(replicaID, originalID);
      }
      let sourceTags = iconic.Tags();
      let tags: array<CName>;
      for tag in sourceTags {
        if NotEquals(tag, n"Quest") {
          ArrayPush(tags, tag);
        }
      }
      ArrayPush(tags, n"TCO_Replica");
      TweakDBManager.SetFlat(replicaID + t".tags", ToVariant(tags));
      // 등급을 Legendary(티어 5)로 고정한다. 원본 레코드의 등급이 Random 이면 바닐라 GetItemCraftingCost 가
      // 플레이어 레벨에 맞춰 티어 2~5 부품(75/55/35/15)을 재료에 덧붙이기 때문이다. 레플리카는 항상 티어 5 이상이며,
      // 최종 티어(5 / 5+ / 5++)는 제작 시 원본과 맞춘다 (TCO_MatchTier).
      TweakDBManager.SetFlat(replicaID + t".quality", ToVariant(t"Quality.Legendary"));
      let noLootEffects: array<TweakDBID>;
      TweakDBManager.SetFlat(replicaID + t".OnLooted", ToVariant(noLootEffects));
      // 비용: 무기별 재정의 패키지(TCO.ReplicaCost.<아이코닉>)가 있으면 그대로, 없으면 프리셋(TCO.Config.replicaPreset)대로 만든다.
      //   base   = 매핑된 기반 무기 + 부품      parts  = 부품만
      //   fusion = 원본 2개 추가 소모, 부품 없음   custom = 설정의 개별 값
      // 기반 무기가 없는 아이코닉(매핑/자동 매칭 모두 실패)은 부품만으로 복제한다.
      let bases: array<TweakDBID>;
      let packageID = this.CustomCostPackage(iconic, iconics);
      if TDBID.IsValid(packageID) {
        bases = this.WeaponIngredients(packageID);
      } else {
        if TCO_Config.ReplicaUseBaseWeapon() {
          bases = this.ResolveBases(iconic, iconics, presets);
          if ArraySize(bases) == 0 {
            this.m_noBaseCount += 1;
          }
        }
        let copies = 0;
        while copies < TCO_Config.ReplicaOriginalCopies() {
          ArrayPush(bases, originalID);
          copies += 1;
        }
        packageID = this.BuildReplicaPackage(replicaID, bases);
      }
      TweakDBManager.SetFlat(replicaID + t".CraftingData", ToVariant(packageID));
      TweakDBManager.SetFlat(replicaID + t".TCO_bases", ToVariant(bases));
      TweakDBManager.SetFlat(replicaID + t".TCO_hasBase", ToVariant(ArraySize(bases) > 0));
      TweakDBManager.SetFlat(replicaID + t".TCO_original", ToVariant(originalID));
      TweakDBManager.UpdateRecord(replicaID);
      TweakDBManager.SetFlat(originalID + t".TCO_replica", ToVariant(replicaID));
      this.m_replicaCount += 1;
    }
  }

  // 기반 무기 결정: 매핑 테이블(직접) > 매핑 테이블(같은 표시 이름의 다른 레코드) > 자동 (같은 종류 + 같은 friendlyName, _Default 우선)
  // 2.x 아이코닉은 등급 변형 레코드(Common_/Uncommon_/Rare_/Epic_/Legendary_<아이코닉>)를 가지며 실제 소지 아이템은
  // 그 변형일 수 있다. 변형은 Preset_<아이코닉> 과 표시 이름이 같으므로 그 매핑을 물려받는다.
  private func ResolveBases(iconic: ref<WeaponItem_Record>, iconics: array<ref<WeaponItem_Record>>, presets: array<ref<WeaponItem_Record>>) -> array<TweakDBID> {
    let result = this.MappedBases(iconic.GetID());
    if ArraySize(result) > 0 {
      return result;
    }
    for other in iconics {
      if ArraySize(result) == 0 && !(other.GetID() == iconic.GetID()) && Equals(other.DisplayName(), iconic.DisplayName()) {
        result = this.MappedBases(other.GetID());
      }
    }
    if ArraySize(result) > 0 {
      return result;
    }
    let friendly = iconic.FriendlyName();
    let itemType = iconic.ItemType().Type();
    let chosen: TweakDBID = TDBID.None();
    let fallback: TweakDBID = TDBID.None();
    if StrLen(friendly) > 0 {
      for preset in presets {
        if Equals(preset.ItemType().Type(), itemType) && Equals(preset.FriendlyName(), friendly) {
          if this.IsDefaultPreset(preset) {
            if !TDBID.IsValid(chosen) { chosen = preset.GetID(); }
          } else {
            if !TDBID.IsValid(fallback) { fallback = preset.GetID(); }
          }
        }
      }
    }
    if !TDBID.IsValid(chosen) { chosen = fallback; }
    if TDBID.IsValid(chosen) {
      ArrayPush(result, chosen);
    }
    return result;
  }

  // TCO.BaseMap.<아이코닉> 매핑 항목의 기반 무기 목록 (없으면 빈 배열)
  private func MappedBases(iconicID: TweakDBID) -> array<TweakDBID> {
    let result: array<TweakDBID>;
    let mapping = TweakDBInterface.GetCraftableRecord(t"TCO.BaseMap." + iconicID);
    if IsDefined(mapping) {
      let items: array<wref<Item_Record>>;
      mapping.CraftableItem(items);
      for item in items {
        if IsDefined(item) {
          ArrayPush(result, item.GetID());
        }
      }
    }
    return result;
  }

  // 무기별 비용 재정의: TCO.ReplicaCost.<아이코닉 레코드> CraftingPackage. 같은 표시 이름의 다른 레코드(등급 변형)에 있으면 그것을 쓴다.
  private func CustomCostPackage(iconic: ref<WeaponItem_Record>, iconics: array<ref<WeaponItem_Record>>) -> TweakDBID {
    let packageID = t"TCO.ReplicaCost." + iconic.GetID();
    if IsDefined(TweakDBInterface.GetCraftingPackageRecord(packageID)) {
      return packageID;
    }
    for other in iconics {
      if !(other.GetID() == iconic.GetID()) && Equals(other.DisplayName(), iconic.DisplayName()) {
        let otherID = t"TCO.ReplicaCost." + other.GetID();
        if IsDefined(TweakDBInterface.GetCraftingPackageRecord(otherID)) {
          return otherID;
        }
      }
    }
    return TDBID.None();
  }

  // 비용 패키지의 재료 중 무기(기반 무기로 소모되는 것)를 수량만큼 펼친 목록
  private func WeaponIngredients(packageID: TweakDBID) -> array<TweakDBID> {
    let result: array<TweakDBID>;
    let package = TweakDBInterface.GetCraftingPackageRecord(packageID);
    if !IsDefined(package) { return result; }
    let elements: array<wref<RecipeElement_Record>>;
    package.CraftingRecipe(elements);
    for element in elements {
      let ingredient = element.Ingredient();
      if IsDefined(ingredient) {
        let category = ingredient.ItemCategory();
        if IsDefined(category) && Equals(category.Type(), gamedataItemCategory.Weapon) {
          let n = 0;
          while n < element.Amount() {
            ArrayPush(result, ingredient.GetID());
            n += 1;
          }
        }
      }
    }
    return result;
  }

  private func BuildReplicaPackage(replicaID: TweakDBID, bases: array<TweakDBID>) -> TweakDBID {
    ArrayClear(this.m_costIds);
    ArrayClear(this.m_costAmounts);
    for baseID in bases {
      this.Accumulate(baseID, 1);
    }
    this.Accumulate(TCO_Config.ReplicaMaterialItem(), TCO_Config.ReplicaMaterialAmount());
    let packageID = replicaID + t"_Cost";
    this.CreatePackageFromAccumulated(packageID);
    return packageID;
  }
}
