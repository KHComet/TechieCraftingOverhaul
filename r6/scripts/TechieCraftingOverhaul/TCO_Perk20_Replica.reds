// ============================================================================
// TCO - 20 특전 "Detail Rigging" (계획된 개조)
//   원본 아이코닉(티어5+)을 분석해 기반 무기(티어5+)를 아이코닉으로 개조한다.
//   - 레플리카 레코드 (<아이코닉>_TCO_Replica) 는 TCO_Tweaks.reds 가 로딩 시 생성
//   - 조건을 만족하는 원본을 소지하면 제작 목록에 레플리카 레시피가 나타난다
//   - 제작 시 기반 무기는 "분해 판정"으로 소모(개조부품 회수) 되고, 원본은 유지된다
//   - 무기 종류당 평생 1회 (세이브에 기록, 레플리카를 분해해도 초기화되지 않음)
// ============================================================================

// ---------------------------------------------------------------------------
// CraftingSystem 후킹
// ---------------------------------------------------------------------------

// 제작 패널은 CraftingSystem.GetPlayerCraftableItems() 를 쓰지 않고 CraftBook 을 직접 읽는다
// (CraftingPanelController.GetRecipesList: HideRecipesForOwnedItems() -> GetCraftableItems()).
// 목록을 읽기 직전에 불리는 HideRecipesForOwnedItems 에서 레플리카 레시피를 동기화한다.
@wrapMethod(CraftBook)
public final func HideRecipesForOwnedItems() -> Void {
  wrappedMethod();
  let owner = this.GetOwner();
  if IsDefined(owner) {
    let sys = TechieCraftingOverhaul.GetInstance(owner.GetGame());
    if IsDefined(sys) {
      sys.SyncReplicaRecipes();
    }
  }
}

// 다른 호출자가 CraftingSystem 경유로 목록을 읽는 경우도 동기화한다.
@wrapMethod(CraftingSystem)
public final const func GetPlayerCraftableItems() -> array<wref<Item_Record>> {
  let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
  if IsDefined(sys) {
    sys.SyncReplicaRecipes();
  }
  return wrappedMethod();
}

// 레플리카의 제작 비용.
//   - 무기별 재정의(TCO.ReplicaCost.<아이코닉>)가 있으면 그 레시피를 바닐라 경로로 읽는다.
//   - 없으면 현재 프리셋/설정대로 그때그때 조합한다 (설정이 게임 중에 바뀔 수 있으므로 로딩 시 고정하지 않는다).
//   - 무기 재료의 보유 수량은 레코드 일치가 아니라 모델 일치(TCO_IsBaseModelInstance)로 센다.
//     바닐라는 재료 레코드와 똑같은 레코드의 아이템만 세므로, 9 특전으로 제작한 무기나 외형 변형은 0 으로 표시된다.
@wrapMethod(CraftingSystem)
public final const func GetItemCraftingCost(itemRecord: wref<Item_Record>) -> array<IngredientData> {
  if !IsDefined(itemRecord) || !itemRecord.TagsContains(n"TCO_Replica") {
    return wrappedMethod(itemRecord);
  }
  let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
  if !IsDefined(sys) {
    return wrappedMethod(itemRecord);
  }
  let replicaID = itemRecord.GetID();
  let ingredients: array<IngredientData>;
  if sys.HasCustomReplicaCost(replicaID) {
    ingredients = wrappedMethod(itemRecord);
  } else {
    ingredients = this.TCO_BuildReplicaCost(replicaID, sys);
  }
  let i = 0;
  while i < ArraySize(ingredients) {
    if IsDefined(ingredients[i].id) && RPGManager.IsItemWeapon(ItemID.CreateQuery(ingredients[i].id.GetID())) {
      ingredients[i].inventoryQuantity = sys.CountAvailableBases(replicaID, ingredients[i].id.GetID());
    }
    i += 1;
  }
  return ingredients;
}

// 프리셋 비용 조합: 필요한 무기(종류별로 묶어 수량 표시) + 부품.
@addMethod(CraftingSystem)
private final const func TCO_BuildReplicaCost(replicaID: TweakDBID, sys: ref<TechieCraftingOverhaul>) -> array<IngredientData> {
  let ingredients: array<IngredientData>;
  let bases = sys.GetReplicaBases(replicaID);
  let seen: array<TweakDBID>;
  for baseID in bases {
    if !ArrayContains(seen, baseID) {
      ArrayPush(seen, baseID);
      let count = 0;
      for other in bases {
        if other == baseID {
          count += 1;
        }
      }
      let baseRecord = TweakDBInterface.GetItemRecord(baseID);
      if IsDefined(baseRecord) {
        ArrayPush(ingredients, this.CreateIngredientData(baseRecord, count));
      }
    }
  }
  let amount = TCO_Config.ReplicaMaterialAmount();
  let materialRecord = TweakDBInterface.GetItemRecord(TCO_Config.ReplicaMaterialItem());
  if amount > 0 && IsDefined(materialRecord) {
    let material = this.CreateIngredientData(materialRecord, amount);
    // 바닐라 GetItemCraftingCost 와 같은 제작 비용 감소(CraftingCostReduction)를 부품에 적용한다
    let owner = this.GetPlayerCraftBook().GetOwner();
    if IsDefined(owner) && material.quantity > 1 {
      let reduction = GameInstance.GetStatsSystem(this.GetGameInstance()).GetStatValue(Cast<StatsObjectID>(owner.GetEntityID()), gamedataStatType.CraftingCostReduction);
      if reduction > 0.0 {
        material.quantity = CeilF(Cast<Float>(material.quantity) * (1.0 - reduction));
      }
    }
    ArrayPush(ingredients, material);
  }
  return ingredients;
}

// 레플리카 제작 가능 판정: 바닐라 판정(재료 레코드 일치) 대신 기반 무기(모델 일치) + 부품 수량으로 판정한다.
@addMethod(CraftingSystem)
private final const func TCO_CanCraftReplicaRecord(itemRecord: wref<Item_Record>) -> Bool {
  let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
  if !IsDefined(sys) || !IsDefined(itemRecord) { return false; }
  if !sys.CanCraftReplica(itemRecord.GetID()) { return false; }
  let materials = this.TCO_ReplicaMaterials(itemRecord);
  return this.HasIngredients(materials);
}

// 레플리카 레시피 재료 중 무기(기반 무기)를 뺀 부품 목록
@addMethod(CraftingSystem)
private final const func TCO_ReplicaMaterials(itemRecord: wref<Item_Record>) -> array<IngredientData> {
  let materials: array<IngredientData>;
  let ingredients = this.GetItemCraftingCost(itemRecord);
  for ingredient in ingredients {
    if IsDefined(ingredient.id) && !RPGManager.IsItemWeapon(ItemID.CreateQuery(ingredient.id.GetID())) {
      ArrayPush(materials, ingredient);
    }
  }
  return materials;
}

// 제작 가능 판정 (목록 항목용)
@wrapMethod(CraftingSystem)
public final const func CanItemBeCrafted(itemRecord: wref<Item_Record>) -> Bool {
  if IsDefined(itemRecord) && itemRecord.TagsContains(n"TCO_Replica") {
    return this.TCO_CanCraftReplicaRecord(itemRecord);
  }
  return wrappedMethod(itemRecord);
}

// 제작 가능 판정 (선택 항목용)
@wrapMethod(CraftingSystem)
public final const func CanItemBeCrafted(itemData: wref<gameItemData>) -> Bool {
  if IsDefined(itemData) && itemData.HasTag(n"TCO_Replica") {
    return this.TCO_CanCraftReplicaRecord(TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemData.GetID())));
  }
  return wrappedMethod(itemData);
}

// 레플리카는 아이코닉 태그가 있어도 분해할 수 있다 (설정으로 끌 수 있음)
@wrapMethod(CraftingSystem)
public final const func CanItemBeDisassembled(itemData: wref<gameItemData>) -> Bool {
  if IsDefined(itemData) && itemData.HasTag(n"TCO_Replica") && TCO_Config.ReplicaDisassembleAllowed() {
    return !itemData.HasTag(n"Quest")
      && !itemData.HasTag(n"UnequipBlocked")
      && IsDefined(ItemActionsHelper.GetDisassembleAction(itemData.GetID()));
  }
  return wrappedMethod(itemData);
}

// 레플리카 제작은 바닐라 CraftItem 대신 전용 흐름으로 처리한다
@wrapMethod(CraftingSystem)
private final func OnCraftItemRequest(request: ref<CraftItemRequest>) -> Void {
  if IsDefined(request.itemRecord) && request.itemRecord.TagsContains(n"TCO_Replica") {
    let crafted = this.TCO_CraftReplica(request.target, request.itemRecord);
    if IsDefined(crafted) {
      this.UpdateBlackboard(CraftingCommands.CraftingFinished, crafted.GetID());
    } else {
      TCO_Notify(this.GetGameInstance(), TCO_Text.ReplicaFailed(this.GetGameInstance()));
      this.UpdateBlackboard(CraftingCommands.Failed);
    }
    return;
  }
  wrappedMethod(request);
}

@addMethod(CraftingSystem)
private final func TCO_CraftReplica(target: wref<GameObject>, replicaRecord: ref<Item_Record>) -> wref<gameItemData> {
  let gi = this.GetGameInstance();
  let sys = TechieCraftingOverhaul.GetInstance(gi);
  let ts = GameInstance.GetTransactionSystem(gi);
  let statsSystem = GameInstance.GetStatsSystem(gi);
  if !IsDefined(sys) || !IsDefined(target) || !IsDefined(replicaRecord) { return null; }
  let replicaID = replicaRecord.GetID();
  if !sys.CanCraftReplica(replicaID) { return null; }

  // 1. 원본 / 기반 무기 인스턴스 선정
  let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
  let originalItem = sys.FindOwnedOriginal(originalID);
  let originalData = ts.GetItemData(target, originalItem);
  let bases = sys.GetReplicaBases(replicaID);
  let chosen: array<ItemID>;
  ArrayPush(chosen, originalItem);
  for baseID in bases {
    let instance = sys.FindBaseInstance(baseID, chosen);
    if !ItemID.IsValid(instance) { return null; }
    ArrayPush(chosen, instance);
  }

  // 2. 부품 검사 (레시피 재료 중 무기가 아닌 것. 기반 무기는 1 에서 모델 기준으로 이미 골랐다)
  let ingredients = this.TCO_ReplicaMaterials(replicaRecord);
  if !this.HasIngredients(ingredients) { return null; }

  // 3. 기반 무기 소모 = 분해 판정 (장착 부품 회수 후 제거)
  let i = 1;
  while i < ArraySize(chosen) {
    let baseItemID = chosen[i];
    let baseData = ts.GetItemData(target, baseItemID);
    let restored: array<ItemAttachments>;
    TCO_CollectRetrievableParts(baseData, restored);
    for attachment in restored {
      ts.RemovePart(target, baseItemID, attachment.attachmentSlotID);
    }
    GameInstance.GetTelemetrySystem(gi).LogItemDisassembled(target, baseItemID);
    ts.RemoveItem(target, baseItemID, 1);
    i += 1;
  }

  // 4. 부품 소모 + 제작 경험치
  let recipeXP = 0;
  for ingredient in ingredients {
    let ingredientID = ingredient.id.GetID();
    if !RPGManager.IsItemWeapon(ItemID.CreateQuery(ingredientID)) {
      ts.RemoveItemByTDBID(target, ingredientID, ingredient.quantity, true);
      recipeXP += TCO_IngredientXP(ingredient.id) * ingredient.baseQuantity;
    }
  }

  // 5. 레플리카 지급, 레벨/제작 표시, 원본과 티어 일치
  let craftedItemID = ItemID.FromTDBID(replicaID);
  ts.GiveItem(target, craftedItemID, 1);
  let craftedData = ts.GetItemData(target, craftedItemID);
  if !IsDefined(craftedData) { return null; }
  this.SetItemLevel(craftedData);
  this.MarkItemAsCrafted(craftedData);
  TCO_MatchTier(statsSystem, originalData, craftedData);

  // 6. 복제 기록, 레시피 숨김, 통계/경험치/알림
  sys.MarkCloned(originalID);
  this.GetPlayerCraftBook().HideRecipe(replicaID, true);
  this.SendItemCraftedDataTrackingRequest(craftedItemID, 1);
  this.ProcessCraftSkill(Cast<Float>(recipeXP));
  TCO_Notify(gi, TCO_Text.ReplicaCrafted(gi, TCO_ItemName(replicaRecord)));
  TCO_Log("Replica crafted: " + TDBID.ToStringDEBUG(replicaID) + " (cloned types: " + IntToString(sys.GetClonedCount()) + ")");
  return craftedData;
}
